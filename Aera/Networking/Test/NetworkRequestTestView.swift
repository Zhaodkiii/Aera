//
//  NetworkRequestTestView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//
//
//  DjangoEndpointsDemo.swift
//  SwiftUI 调用本机 Django 测试接口（含 ETag 缓存 / 错误处理 / 并发去重）
//

import SwiftUI

// ========== 1. 基础配置 ==========

/// 本机 Django 服务基地址：
/// - 模拟器：localhost:1029 就能访问宿主机
/// - 真机：把 BASE_URL 换成电脑局域网 IP，如 "http://192.168.1.100:1029"
private let BASE_URL = URL(string: "http://localhost:1029")!

// ========== 2. 通用协议/模型 ==========

/// 可解码的响应体
protocol HTTPResponseBody: Decodable {}

/// 泛型 HTTP 响应容器
struct HTTPResponse<Body: HTTPResponseBody> {
    let statusCode: Int
    let headers: [AnyHashable: Any]
    let body: Body
}

/// 统一的网络错误
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodeError(Error)
    case noCachedData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL 无效"
        case .requestFailed(let e): return "请求失败：\(e.localizedDescription)"
        case .invalidResponse: return "响应无效或缺少数据"
        case .httpError(let c, let m): return "HTTP 错误（\(c)）：\(m)"
        case .decodeError(let e): return "解码失败：\(e.localizedDescription)"
        case .noCachedData: return "收到 304 但本地没有缓存"
        }
    }
}

// ========== 3. ETag 简易缓存（If-None-Match / 304） ==========

final class ETagManager {
    private var memory: [String: (etag: String, data: Data)] = [:]
    private let lock = NSLock()
    private func key(_ url: URL) -> String { url.absoluteString }
    
    func etag(for url: URL) -> String? {
        lock.lock(); defer { lock.unlock() }
        return memory[key(url)]?.etag
    }
    func cachedData(for url: URL) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return memory[key(url)]?.data
    }
    func store(url: URL, data: Data, etag: String) {
        lock.lock(); defer { lock.unlock() }
        memory[key(url)] = (etag, data)
    }
}

// ========== 4. HTTPClient：GET / POST / 错误 / ETag / 去重 ==========

final class HTTPClient {
    typealias Raw = Result<(status: Int, headers: [AnyHashable: Any], data: Data), NetworkError>
    typealias Waiter = (Raw) -> Void
    
    private let baseURL: URL
    private let session: URLSession
    private let etag = ETagManager()
    private var inFlight: [String: [Waiter]] = [:]
    private let lock = NSLock()
    
    private let defaultHeaders = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    
    init(baseURL: URL) {
        self.baseURL = baseURL
        let cfg = URLSessionConfiguration.ephemeral
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.urlCache = nil
        self.session = URLSession(configuration: cfg)
    }
    
    // —— GET
    func get<T: HTTPResponseBody>(_ path: String) async -> Result<HTTPResponse<T>, NetworkError> {
        await request(path: path, method: "GET", body: Data?.none, expecting: T.self)
    }
    
    // —— POST（发送 JSON）
    func post<T: HTTPResponseBody, Body: Encodable>(_ path: String, json body: Body) async -> Result<HTTPResponse<T>, NetworkError> {
        do {
            let data = try JSONEncoder().encode(body)
            return await request(path: path, method: "POST", body: data, expecting: T.self)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    
    // —— 真正的请求实现（含 ETag / 错误映射 / 去重）
    private func request<T: HTTPResponseBody>(path: String, method: String, body: Data?, expecting: T.Type) async -> Result<HTTPResponse<T>, NetworkError> {
        guard let url = URL(string: path, relativeTo: baseURL) else { return .failure(.invalidURL) }
        let key = "\(method):\(url.absoluteString):\(body?.hashValue ?? 0)"
        
        // 如果有正在飞行的同请求，挂起等待
        if let raw = await waitIfInFlight(key: key) {
            return mapRaw(raw, to: T.self)
        }
        beginFlight(key: key)
        
        // 组装 URLRequest
        var req = URLRequest(url: url)
        req.httpMethod = method
        defaultHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        if method == "POST" { req.httpBody = body }
        if let tag = etag.etag(for: url) { req.setValue(tag, forHTTPHeaderField: "If-None-Match") }
        print(url)

        // 发送
        let raw: Raw
        do {
            let (data, rsp) = try await session.data(for: req)
            guard let http = rsp as? HTTPURLResponse else {
                raw = .failure(.invalidResponse)
                endFlight(key: key, with: raw); return mapRaw(raw, to: T.self)
            }
            let status = http.statusCode
            // 命中 304：使用缓存
            if status == 304 {
                if let cached = etag.cachedData(for: url) {
                    raw = .success((status, http.allHeaderFields, cached))
                } else {
                    raw = .failure(.noCachedData)
                }
                endFlight(key: key, with: raw); return mapRaw(raw, to: T.self)
            }
            // 4xx / 5xx 错误
            if status >= 400 {
                let msg = String(data: data, encoding: .utf8) ?? "HTTP \(status) 错误"
                raw = .failure(.httpError(statusCode: status, message: msg))
                endFlight(key: key, with: raw); return mapRaw(raw, to: T.self)
            }
            // 存 ETag
            if let et = http.value(forHTTPHeaderField: "ETag") {
                etag.store(url: url, data: data, etag: et)
            }
            raw = .success((status, http.allHeaderFields, data))
        } catch {
            raw = .failure(.requestFailed(error))
        }
        
        endFlight(key: key, with: raw)
        return mapRaw(raw, to: T.self)
    }
    
    // —— 并发去重：等待已有飞行请求结果
    private func waitIfInFlight(key: String) async -> Raw? {
        await withCheckedContinuation { cont in
            lock.lock()
            if var arr = inFlight[key] {
                arr.append { raw in cont.resume(returning: raw) }
                inFlight[key] = arr
                lock.unlock()
            } else {
                lock.unlock()
                cont.resume(returning: nil)
            }
        }
    }
    private func beginFlight(key: String) {
        lock.lock(); inFlight[key] = []; lock.unlock()
    }
    private func endFlight(key: String, with raw: Raw) {
        lock.lock(); let waiters = inFlight.removeValue(forKey: key) ?? []; lock.unlock()
        waiters.forEach { $0(raw) }
    }
    private func mapRaw<T: HTTPResponseBody>(_ raw: Raw, to: T.Type) -> Result<HTTPResponse<T>, NetworkError> {
        switch raw {
        case .failure(let e): return .failure(e)
        case .success(let tuple):
            do {
                let obj = try JSONDecoder().decode(T.self, from: tuple.data)
                return .success(.init(statusCode: tuple.status, headers: tuple.headers, body: obj))
            } catch {
                return .failure(.decodeError(error))
            }
        }
    }
}

// ========== 5. 针对你的 Django 路由的模型 ==========

struct PingResp: HTTPResponseBody { let ok: Bool; let hello: String }
struct NoteReq: Encodable { let title: String; let content: String }
struct NoteResp: HTTPResponseBody { let id: Int; let title: String?; let content: String? }
struct ETagResp: HTTPResponseBody { let version: Int; let data: [Int] }

// 错误路由可能返回 {"code":400,"message":"..."}，这里只用字符串兜底展示

// ========== 6. SwiftUI ViewModel：封装各个接口调用 ==========

@MainActor
final class DjangoVM: ObservableObject {
    @Published var output: [String] = []
    @Published var isLoading = false
    
    private let client = HTTPClient(baseURL: BASE_URL)
    
    private func log(_ s: String) { output.append(s) }
    func clear() { output.removeAll() }
    
    // GET /ping
    func ping() async {
        isLoading = true; defer { isLoading = false }
        log("➡️ GET /ping")
        let res: Result<HTTPResponse<PingResp>, NetworkError> = await client.get("/testnet/ping")
        switch res {
        case .success(let r):
            log("✅ \(r.statusCode) ok=\(r.body.ok), hello=\(r.body.hello)")
        case .failure(let e):
            log("❌ \(e.localizedDescription)")
        }
    }
    
    // POST /notes
    func createNote() async {
        isLoading = true; defer { isLoading = false }
        log("➡️ POST /notes")
        let body = NoteReq(title: "测试标题", content: "这是内容")
        let res: Result<HTTPResponse<NoteResp>, NetworkError> = await client.post("/testnet/notes", json: body)
        switch res {
        case .success(let r):
            log("✅ \(r.statusCode) id=\(r.body.id) title=\(r.body.title ?? "-")")
        case .failure(let e):
            log("❌ \(e.localizedDescription)")
        }
    }
    
    // GET /etag  — 第二次点击应命中 If-None-Match → 304 → 本地缓存
    func etag() async {
        isLoading = true; defer { isLoading = false }
        log("➡️ GET /etag")
        let res: Result<HTTPResponse<ETagResp>, NetworkError> = await client.get("/testnet/etag")
        switch res {
        case .success(let r):
            log("✅ \(r.statusCode) version=\(r.body.version) data=\(r.body.data)")
            if let et = r.headers["ETag"] as? String { log("ℹ️ ETag: \(et)") }
        case .failure(let e):
            log("❌ \(e.localizedDescription)")
        }
    }
    
    // 错误路由
    func bad() async { await hitSimple(path: "/testnet/bad", name: "bad") }
    func unauth() async { await hitSimple(path: "/testnet/unauth", name: "unauth") }
    func tooMany() async { await hitSimple(path: "/testnet/too_many", name: "too_many") }
    func boom() async { await hitSimple(path: "/testnet/boom", name: "boom") }
    func redirect() async { await hitSimple(path: "/testnet/redirect", name: "redirect(307)") }
    func maybe500() async { await hitSimple(path: "/testnet/maybe500", name: "maybe500") }
    
    /// 用 Data→String 兜底打印的通用 GET（不做解码，只看状态/体）
    private func hitSimple(path: String, name: String) async {
        isLoading = true; defer { isLoading = false }
        log("➡️ GET \(path)")
        // 复用 client 的 request 通道：这里临时实现一个“原始” GET 查看文本
        guard let url = URL(string: path, relativeTo: BASE_URL) else {
            log("❌ URL 无效"); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        do {
            let (data, rsp) = try await URLSession.shared.data(for: req)
            guard let http = rsp as? HTTPURLResponse else {
                log("❌ 非 HTTP 响应"); return
            }
            let txt = String(data: data, encoding: .utf8) ?? "<非 UTF-8 内容>"
            log("↩️ \(name) → \(http.statusCode)\n\(txt)")
        } catch {
            log("❌ \(name) 失败：\(error.localizedDescription)")
        }
    }
}

// ========== 7. SwiftUI 界面：按钮一键测试 ==========

struct DjangoEndpointsDemoView: View {
    @StateObject var vm = DjangoVM()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // 操作区
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Group {
                            Button("GET /ping") { Task { await vm.ping() } }
                            Button("POST /notes") { Task { await vm.createNote() } }
                            Button("GET /etag") { Task { await vm.etag() } }
                        }
                        Divider().frame(height: 24)
                        Group {
                            Button("/bad") { Task { await vm.bad() } }
                            Button("/unauth") { Task { await vm.unauth() } }
                            Button("/too_many") { Task { await vm.tooMany() } }
                            Button("/boom") { Task { await vm.boom() } }
                            Button("/redirect") { Task { await vm.redirect() } }
                            Button("/maybe500") { Task { await vm.maybe500() } }
                        }
                        Divider().frame(height: 24)
                        Button("清空日志") { vm.clear() }.foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 8)
                }
                
                // 日志输出
                GroupBox("日志输出") {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(vm.output.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 320)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Django 接口测试")
            .toolbar { if vm.isLoading { ProgressView() } }
        }
    }
}

// ========== 8. 预览 ==========

struct DjangoEndpointsDemoView_Previews: PreviewProvider {
    static var previews: some View {
        DjangoEndpointsDemoView()
    }
}

//
//  NetworkRequestTestView.swift
//  SwiftUI 网络请求完整测试（含中文注释）
//
//  功能点：
//  1）网络请求模块：统一的 HTTPClient（构建 URLRequest、默认 Header、发起请求）
//  2）错误处理模块：NetworkError 统一封装（URL 无效、请求失败、解码失败、HTTP 错误、签名失败、无缓存）
//  3）缓存管理模块：ETagManager（If-None-Match / ETag；304 使用本地缓存）
//  4）响应解析模块：HTTPResponseBody 协议 + 泛型 HTTPResponse 容器
//  5）签名与验证模块：基于 HMAC-SHA256 的简单请求/响应签名（演示用）
//  6）回调与状态管理：对同一 URL 的并发请求做去重，复用同一网络层任务并 fan-out 回调
//
//  使用方式：
//  - 将本文件添加到你的 SwiftUI App 工程；
//  - 在 App 的入口里把 ContentView 设为根视图（或直接在预览里跑）。
//
//
//import SwiftUI
//import CryptoKit
//
//// MARK: - 一、通用模型与协议
//
///// 约束“响应体”类型：只要是可解码的模型都能作为响应体
//protocol HTTPResponseBody: Decodable {}
//
///// 包装一次完整的 HTTP 响应（含状态码与解码后的模型）
//struct HTTPResponse<Body: HTTPResponseBody> {
//    let statusCode: Int
//    let body: Body
//}
//
///// 统一错误定义：让上层只处理这一套错误
//enum NetworkError: Error, LocalizedError {
//    case invalidURL
//    case requestFailed(Error)
//    case invalidResponse
//    case httpError(statusCode: Int, message: String)
//    case decodeError(Error)
//    case invalidSignature
//    case noCachedData
//    
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL:
//            return "URL 无效"
//        case .requestFailed(let e):
//            return "请求失败：\(e.localizedDescription)"
//        case .invalidResponse:
//            return "响应无效或缺少数据"
//        case .httpError(let code, let msg):
//            return "HTTP 错误（\(code)）：\(msg)"
//        case .decodeError(let e):
//            return "解码失败：\(e.localizedDescription)"
//        case .invalidSignature:
//            return "签名校验失败，响应不可信"
//        case .noCachedData:
//            return "收到 304 但本地无缓存"
//        }
//    }
//}
//
//// MARK: - 二、签名与验证（演示版）
///// 用 HMAC-SHA256 做简易签名（演示用途）
///// 真实业务应配合服务端公私钥/Nonce/时间戳/防重放等机制
//struct SignatureUtil {
//    private static let secretKey = "my_shared_secret"  // 演示密钥，生产请妥善保管/替换
//    
//    /// 为请求添加签名头（X-Signature）
//    static func sign(request: inout URLRequest) {
//        guard let url = request.url else { return }
//        let method = request.httpMethod ?? "GET"
//        // 这里演示只签名 method + path，如果有 body/query，建议一并纳入
//        let toSign = Data((method + url.path).utf8)
//        let key = SymmetricKey(data: Data(secretKey.utf8))
//        let sig = HMAC<SHA256>.authenticationCode(for: toSign, using: key)
//        let hex = sig.map { String(format: "%02x", $0) }.joined()
//        request.setValue(hex, forHTTPHeaderField: "X-Signature")
//    }
//    
//    /// 校验响应签名（X-Signature 对应响应 data）
//    static func verify(response: HTTPURLResponse, data: Data) -> Bool {
//        guard let remoteSig = response.value(forHTTPHeaderField: "X-Signature") else {
//            // 没有签名头，示例里默认放行；若你要求强校验可改为 false
//            return true
//        }
//        let key = SymmetricKey(data: Data(secretKey.utf8))
//        let expected = HMAC<SHA256>.authenticationCode(for: data, using: key)
//        let expectedHex = expected.map { String(format: "%02x", $0) }.joined()
//        return expectedHex == remoteSig
//    }
//}
//
//// MARK: - 三、ETag 缓存管理（If-None-Match / ETag -> 304 命中本地缓存）
//final class ETagManager {
//    /// 简易缓存：内存 + UserDefaults（进程内与重启后都能用）
//    private var memory: [String: (etag: String, data: Data)] = [:]
//    private let udKeyPrefix = "ETagCache."
//    private let lock = NSLock()
//    
//    func eTag(for url: URL) -> String? {
//        lock.lock(); defer { lock.unlock() }
//        if let m = memory[url.absoluteString]?.etag { return m }
//        if let dict = UserDefaults.standard.dictionary(forKey: udKeyPrefix + url.absoluteString),
//           let etag = dict["etag"] as? String {
//            return etag
//        }
//        return nil
//    }
//    
//    func cachedData(for url: URL) -> Data? {
//        lock.lock(); defer { lock.unlock() }
//        if let m = memory[url.absoluteString]?.data { return m }
//        if let dict = UserDefaults.standard.dictionary(forKey: udKeyPrefix + url.absoluteString),
//           let base64 = dict["dataBase64"] as? String,
//           let data = Data(base64Encoded: base64) {
//            return data
//        }
//        return nil
//    }
//    
//    func store(url: URL, data: Data, eTag: String) {
//        lock.lock()
//        memory[url.absoluteString] = (eTag, data)
//        lock.unlock()
//        let dict: [String: Any] = ["etag": eTag, "dataBase64": data.base64EncodedString()]
//        UserDefaults.standard.set(dict, forKey: udKeyPrefix + url.absoluteString)
//    }
//}
//
//// MARK: - 四、HTTPClient（请求 / 错误 / ETag / 签名 / 回调去重）
//final class HTTPClient {
//    typealias RawResult = Result<(status: Int, data: Data), NetworkError>
//    typealias WaitingCallback = (RawResult) -> Void
//    
//    private let baseURL: URL
//    private let session: URLSession
//    private let etagManager = ETagManager()
//    
//    // 回调去重：同一 URL 正在进行的请求，只发一次网络；多个调用共用结果
//    private var inFlight: [String: [WaitingCallback]] = [:]
//    private let lock = NSLock()
//    
//    // 默认头
//    private let defaultHeaders: [String: String] = [
//        "Accept": "application/json",
//        "Content-Type": "application/json"
//    ]
//    
//    init(baseURL: URL) {
//        self.baseURL = baseURL
//        let cfg = URLSessionConfiguration.ephemeral
//        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
//        cfg.urlCache = nil
//        self.session = URLSession(configuration: cfg)
//    }
//    
//    /// GET 请求（支持 ETag / 304 / 回调去重 / 签名 / 错误映射 / 泛型解码）
//    func get<T: HTTPResponseBody>(_ path: String) async -> Result<HTTPResponse<T>, NetworkError> {
//        // 构造 URL
//        guard let url = URL(string: path, relativeTo: baseURL) else {
//            return .failure(.invalidURL)
//        }
//        let key = "GET:\(url.absoluteString)"
//        
//        // 回调去重：如果已在飞行，挂起等待同一网络结果
//        if let result = await waitIfInFlight(key: key) {
//            return mapRawResult(result, to: T.self)
//        }
//        
//        // 入队一个回调占位，表示开始飞行
//        beginFlight(key: key)
//        
//        // 构造 URLRequest
//        var req = URLRequest(url: url)
//        req.httpMethod = "GET"
//        defaultHeaders.forEach { req.setValue($1, forHTTPHeaderField: $0) }
//        if let etag = etagManager.eTag(for: url) {
//            req.setValue(etag, forHTTPHeaderField: "If-None-Match")
//        }
//        SignatureUtil.sign(request: &req)
//        
//        // 发起请求
//        let raw: RawResult
//        do {
//            let (data, rsp) = try await session.data(for: req)
//            guard let http = rsp as? HTTPURLResponse else {
//                raw = .failure(.invalidResponse)
//                endFlight(key: key, with: raw)
//                return mapRawResult(raw, to: T.self)
//            }
//            let status = http.statusCode
//            
//            if status == 304 {
//                // 命中 304：从缓存拿数据
//                if let cached = etagManager.cachedData(for: url) {
//                    raw = .success((status: status, data: cached))
//                } else {
//                    raw = .failure(.noCachedData)
//                }
//                endFlight(key: key, with: raw)
//                return mapRawResult(raw, to: T.self)
//            }
//            
//            if status >= 400 {
//                // HTTP 错误：尝试给出尽量清晰的错误信息
//                let msg = String(data: data, encoding: .utf8) ?? "HTTP \(status) 错误"
//                raw = .failure(.httpError(statusCode: status, message: msg))
//                endFlight(key: key, with: raw)
//                return mapRawResult(raw, to: T.self)
//            }
//            
//            // 校验响应签名（无签名头默认通过；你可按需强制）
//            guard SignatureUtil.verify(response: http, data: data) else {
//                raw = .failure(.invalidSignature)
//                endFlight(key: key, with: raw)
//                return mapRawResult(raw, to: T.self)
//            }
//            
//            // 存入 ETag 缓存（如果服务端返回）
//            if let etag = http.value(forHTTPHeaderField: "ETag") {
//                etagManager.store(url: url, data: data, eTag: etag)
//            }
//            
//            raw = .success((status: status, data: data))
//        } catch {
//            raw = .failure(.requestFailed(error))
//        }
//        
//        // fan-out 通知所有等待者
//        endFlight(key: key, with: raw)
//        // 返回泛型结果
//        return mapRawResult(raw, to: T.self)
//    }
//    
//    /// 等待同一 key 的飞行请求结果（若存在）；若无，则返回 nil 表示可发起新请求
//    private func waitIfInFlight(key: String) async -> RawResult? {
//        await withCheckedContinuation { continuation in
//            lock.lock()
//            if var callbacks = inFlight[key] {
//                // 已在飞行：追加一个等待回调，并立即返回 rawResult 由回调触发
//                callbacks.append { raw in
//                    continuation.resume(returning: raw)
//                }
//                inFlight[key] = callbacks
//                lock.unlock()
//            } else {
//                // 不在飞行：告知外部可以发起请求
//                lock.unlock()
//                continuation.resume(returning: nil)
//            }
//        }
//    }
//    
//    /// 标记某 key 已开始飞行（插入一个空数组用于后续挂接等待回调）
//    private func beginFlight(key: String) {
//        lock.lock()
//        inFlight[key] = []
//        lock.unlock()
//    }
//    
//    /// 结束飞行：将结果广播给所有等待者并清理
//    private func endFlight(key: String, with raw: RawResult) {
//        lock.lock()
//        let waiters = inFlight.removeValue(forKey: key) ?? []
//        lock.unlock()
//        waiters.forEach { cb in cb(raw) }
//    }
//    
//    /// 将 RawResult 映射为泛型的解码结果
//    private func mapRawResult<T: HTTPResponseBody>(_ raw: RawResult, to: T.Type) -> Result<HTTPResponse<T>, NetworkError> {
//        switch raw {
//        case .failure(let e):
//            return .failure(e)
//        case .success(let tuple):
//            do {
//                let obj = try JSONDecoder().decode(T.self, from: tuple.data)
//                return .success(.init(statusCode: tuple.status, body: obj))
//            } catch {
//                return .failure(.decodeError(error))
//            }
//        }
//    }
//}
//
//// MARK: - 五、示例数据模型（按你的业务替换）
//struct UserInfo: HTTPResponseBody {
//    let id: Int
//    let name: String
//}
//
//// MARK: - 六、SwiftUI ViewModel（演示调用、错误展示、并发测试）
//final class NetworkTestViewModel: ObservableObject {
//    @Published var user: UserInfo?
//    @Published var log: [String] = []
//    @Published var isLoading = false
//    @Published var errorText: String?
//    
//    // 公开测试 API（可改为你的域名）
//    private let client = HTTPClient(baseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
//    
//    /// 单次发起请求（含 UI 状态管理）
//    @MainActor
//    func fetchOnce() async {
//        isLoading = true
//        errorText = nil
//        log.append("➡️ 发起 /users/1 请求")
//        defer { isLoading = false }
//        
//        let result: Result<HTTPResponse<UserInfo>, NetworkError> = await client.get("/users/1")
//        switch result {
//        case .success(let resp):
//            user = resp.body
//            log.append("✅ 成功（\(resp.statusCode)）：\(resp.body.name)")
//        case .failure(let e):
//            errorText = e.localizedDescription
//            log.append("❌ 失败：\(e.localizedDescription)")
//        }
//    }
//    
//    /// 并发发起多次相同请求，测试“回调去重”
//    @MainActor
//    func fetchConcurrent() async {
//        isLoading = true
//        errorText = nil
//        log.append("🚀 并发 3 次相同请求，测试去重")
//        defer { isLoading = false }
//        
//        await withTaskGroup(of: Void.self) { group in
//            for i in 1...3 {
//                group.addTask { [weak self] in
//                    guard let self else { return }
//                    let result: Result<HTTPResponse<UserInfo>, NetworkError> = await self.client.get("/users/1")
//                    await MainActor.run {
//                        switch result {
//                        case .success(let resp):
//                            self.user = resp.body
//                            self.log.append("✅[并发\(i)] 状态\(resp.statusCode)：\(resp.body.name)")
//                        case .failure(let e):
//                            self.log.append("❌[并发\(i)] \(e.localizedDescription)")
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - 七、SwiftUI 测试界面
//struct NetworkRequestTestView: View {
//    @StateObject private var vm = NetworkTestViewModel()
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 16) {
//                // 结果展示
//                GroupBox("当前用户信息") {
//                    if let u = vm.user {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("ID：\(u.id)")
//                            Text("Name：\(u.name)")
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    } else {
//                        Text("暂无数据").foregroundColor(.secondary)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                }
//                
//                // 错误展示
//                if let err = vm.errorText {
//                    Text("错误：\(err)")
//                        .foregroundColor(.red)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                
//                // 操作按钮
//                HStack {
//                    Button {
//                        Task { await vm.fetchOnce() }
//                    } label: {
//                        Label("请求一次", systemImage: "arrow.clockwise")
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .disabled(vm.isLoading)
//                    
//                    Button {
//                        Task { await vm.fetchConcurrent() }
//                    } label: {
//                        Label("并发 3 次（去重）", systemImage: "square.stack.3d.up.fill")
//                    }
//                    .buttonStyle(.bordered)
//                    .disabled(vm.isLoading)
//                }
//                
//                // 日志输出
//                GroupBox("调试日志") {
//                    ScrollView {
//                        LazyVStack(alignment: .leading, spacing: 8) {
//                            ForEach(Array(vm.log.enumerated()), id: \.offset) { _, line in
//                                Text(line).font(.caption)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//                        }
//                        .padding(.vertical, 6)
//                    }
//                    .frame(maxHeight: 220)
//                }
//            }
//            .padding()
//            .navigationTitle("网络请求完整测试")
//            .toolbar {
//                if vm.isLoading {
//                    ProgressView()
//                }
//            }
//            .task {
//                // 进入页面自动拉一次
//                await vm.fetchOnce()
//            }
//        }
//    }
//}
//
//// MARK: - 八、预览
//struct NetworkRequestTestView_Previews: PreviewProvider {
//    static var previews: some View {
//        NetworkRequestTestView()
//    }
//}
