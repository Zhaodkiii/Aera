//
//  HTTPClient.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/18.
//

import Foundation

// MARK: - Logger (简单日志)
enum LogLevel { case debug, info, warn, error }
struct Logger {
    static var enableVerbose = true
    static func log(_ level: LogLevel, _ msg: @autoclosure () -> String) {
        #if DEBUG
        if enableVerbose { print("[\(level)] \(msg())") }
        #endif
    }
}

// MARK: - HTTP 基础类型
enum HTTPMethod: String { case GET, POST }
typealias HTTPHeaders = [String: String]

protocol Endpoint {
    /// 主 API Host
    static var serverURL: URL { get }
    /// 备用 Host（可为空）
    var fallbackHosts: [URL] { get }
    /// 是否需要认证（决定是否附加 Authorization）
    var requiresAuth: Bool { get }
    /// 是否参与 ETag 缓存
    var usesETag: Bool { get }
    /// 相对路径（拼接到 base）
    var path: String { get }
    /// 端点名（用于诊断与日志）
    var name: String { get }
}

extension Endpoint {
    var fallbackHosts: [URL] { [] }
    func url(base: URL? = nil, fallbackIndex: Int? = nil) -> URL {
        let baseURL: URL
        if let idx = fallbackIndex, fallbackHosts.indices.contains(idx) {
            baseURL = fallbackHosts[idx]
        } else {
            baseURL = base ?? Self.serverURL
        }
        return URL(string: path, relativeTo: baseURL)!
    }
}

// MARK: - 请求体
protocol HTTPRequestBody: Encodable {
    /// 用于签名/回放保护时的确定性参数序列（可选）
    var contentForSignature: [(key: String, value: String?)] { get }
}
extension HTTPRequestBody { var contentForSignature: [(key: String, value: String?)] { [] } }

// MARK: - 请求模型
struct HTTPRequest {
    var method: HTTPMethod
    var endpoint: Endpoint
    var headers: HTTPHeaders = [:]
    var body: HTTPRequestBody?
    /// 是否允许 HTTPClient 自动重试（429/5xx 等）
    var isRetryable: Bool = true
    /// 用于支持备用 Host 的游标
    fileprivate var fallbackIndex: Int? = nil
}

// MARK: - 响应体解码协议
protocol HTTPResponseBody {
    static func create(with data: Data) throws -> Self
    /// 有些模型会携带服务端时间，可通过该接口更新（默认 no-op）
    func copy(with newRequestDate: Date) -> Self
}
extension HTTPResponseBody {
    func copy(with newRequestDate: Date) -> Self { self }
}
extension Data: HTTPResponseBody {
    static func create(with data: Data) throws -> Data { data }
}
extension Decodable {
    static func create(with data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}

// MARK: - 状态码
enum HTTPStatusCode: Equatable {
    case code(Int)
    var raw: Int {
        switch self { case .code(let v): return v }
    }
    var isSuccess: Bool { (200...399).contains(raw) }
    var isServerError: Bool { (500...599).contains(raw) }
    var isNotModified: Bool { raw == 304 }
    static func from(_ status: Int) -> HTTPStatusCode { .code(status) }
}

// MARK: - HTTP 响应与已验证响应
struct HTTPResponse<Body: HTTPResponseBody> {
    let status: HTTPStatusCode
    let headers: [AnyHashable: Any]
    let body: Body
    let requestDate: Date?
    enum Origin { case backend, cache }
    let origin: Origin
}

struct VerifiedHTTPResponse<Body: HTTPResponseBody> {
    let response: HTTPResponse<Body>
    enum Verification { case notRequested, ok, failed }
    let verification: Verification
    var status: HTTPStatusCode { response.status }
    var headers: [AnyHashable: Any] { response.headers }
    var body: Body { response.body }
    var requestDate: Date? { response.requestDate }
    var origin: HTTPResponse<Body>.Origin { response.origin }
//    func mapBody<T: HTTPResponseBody>(_ f: (Body) throws -> T) rethrows -> VerifiedHTTPResponse<T> {
//        let new = try f(response.body)
//        return .init(
//            response: .init(status: response.status, headers: response.headers, body: new, requestDate: response.requestDate, origin: response.origin),
//            verification: verification
//        )
//    }
}

// MARK: - 重定向日志
final class RedirectLoggerDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        Logger.log(.debug, "Redirect: \(response.url?.absoluteString ?? "") -> \(request.url?.absoluteString ?? "")")
        completionHandler(request)
    }
}

// MARK: - HTTPClient
final class HTTPClient {
    struct Config {
        let apiKey: String?
        let requestTimeout: TimeInterval
        let retriableStatus: Set<Int>   // e.g. [429]
        init(apiKey: String? = nil, requestTimeout: TimeInterval = 15, retriableStatus: Set<Int> = [429]) {
            self.apiKey = apiKey
            self.requestTimeout = requestTimeout
            self.retriableStatus = retriableStatus
        }
    }

    private let session: URLSession
    private let config: Config
    private let etag: ETagManager
    private let dns: DNSCheckerType.Type

    /// 退避序列（秒）
    private let backoff: [TimeInterval] = [0, 0.75, 3]

    init(config: Config, etag: ETagManager = .init(), dnsChecker: DNSCheckerType.Type = DNSChecker.self) {
        self.config = config
        let conf = URLSessionConfiguration.ephemeral
        conf.httpMaximumConnectionsPerHost = 1
        conf.timeoutIntervalForRequest = config.requestTimeout
        conf.timeoutIntervalForResource = config.requestTimeout
        conf.urlCache = nil
        self.session = URLSession(configuration: conf, delegate: RedirectLoggerDelegate(), delegateQueue: nil)
        self.etag = etag
        self.dns = dnsChecker
    }

    // 统一默认头
    private func defaultHeaders() -> HTTPHeaders {
        var h: HTTPHeaders = [
            "Content-Type": "application/json",
            "X-Client-Bundle-ID": Bundle.main.bundleIdentifier ?? "unknown",
        ]
        if let key = config.apiKey { h["Authorization"] = "Bearer \(key)" }
        return h
    }

    /// 执行请求，解析为目标类型
    func perform<T: HTTPResponseBody>(_ request: HTTPRequest,
                                      responseType: T.Type = T.self,
                                      completion: @escaping (Result<VerifiedHTTPResponse<T>, NetworkError>) -> Void) {
        start(request, retryCount: 0, completion: completion)
    }

    // 内部：带重试与 fallback 的启动
    private func start<T: HTTPResponseBody>(_ req: HTTPRequest,
                                            retryCount: Int,
                                            completion: @escaping (Result<VerifiedHTTPResponse<T>, NetworkError>) -> Void) {
        var request = req

        // 计算 URL（考虑 fallback）
        let url = request.endpoint.url(fallbackIndex: request.fallbackIndex)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // 组头
        var headers = defaultHeaders()
        if request.endpoint.requiresAuth, let key = config.apiKey {
            headers["Authorization"] = "Bearer \(key)"
        }
        // ETag 请求头
        if request.endpoint.usesETag {
            let etagHeaders = etag.eTagHeaders(for: urlRequest, refreshIfRetried: retryCount > 0)
            headers.merge(etagHeaders, uniquingKeysWith: { $1 })
        }
        // 自定义头
        headers.merge(request.headers, uniquingKeysWith: { $1 })
        urlRequest.allHTTPHeaderFields = headers

        // Body
        if let body = request.body {
            do { urlRequest.httpBody = try JSONEncoder().encode(AnyEncodable(body)) }
            catch { completion(.failure(.unableToCreateRequest(path: request.endpoint.path))); return }
        }

        Logger.log(.debug, "→ \(request.method.rawValue) \(url.absoluteString) headers=\(headers) retry#\(retryCount)")

        let start = Date()
        session.dataTask(with: urlRequest) { [weak self] data, resp, err in
            guard let self else { return }

            // 1) 传输错误 → DNS 拦截判定
            if let err = err {
                let netErr = self.dns.errorWithBlockedHost(from: err)
                if case .dnsError = netErr {
                    completion(.failure(netErr)); return
                }
                // 可否重试（如 先尝试 fallback host）
                if request.isRetryable, let next = self.nextFallbackRequest(request) {
                    Logger.log(.warn, "Transport error, try next fallback host")
                    self.start(next, retryCount: retryCount, completion: completion)
                } else {
                    completion(.failure(.networkError(err as NSError)))
                }
                return
            }

            guard let http = resp as? HTTPURLResponse else {
                completion(.failure(.unexpectedResponse(resp))); return
            }
            let status = HTTPStatusCode.from(http.statusCode)
            Logger.log(.debug, "← \(http.statusCode) \(url.absoluteString) in \(Date().timeIntervalSince(start))s")

            // 2) ETag：304 使用缓存；否则尝试写缓存
            let effectiveData: Data?
            if status.isNotModified {
                // 从缓存取
                if let cached = self.etag.cachedBody(for: urlRequest) {
                    effectiveData = cached
                } else {
                    // 没缓存但 304：若允许重试则强制刷新一次
                    if request.isRetryable && retryCount < self.backoff.count {
                        Logger.log(.warn, "304 but no cache, retry without ETag…")
                        // “刷新 ETag” 实现为：下一次 eTagHeaders 不带 If-None-Match
                        self.start(request, retryCount: retryCount + 1, completion: completion)
                        return
                    } else {
                        effectiveData = nil
                    }
                }
            } else {
                effectiveData = data
                if request.endpoint.usesETag, let body = data {
                    self.etag.storeIfPossible(response: body, headers: http.allHeaderFields, for: urlRequest, status: status.raw)
                }
            }

            // 3) 非成功状态转后端错误
            guard status.isSuccess, let bodyData = effectiveData ?? Data() as Data? else {
                let err = ErrorResponse.from(data: effectiveData ?? Data(), headers: http.allHeaderFields, fallbackStatus: status.raw)
                completion(.failure(.errorResponse(err, status)))
                return
            }

            // 4) 解析 Body
            do {
                let parsed = try T.create(with: bodyData)
                let resp = HTTPResponse(status: status, headers: http.allHeaderFields, body: parsed,
                                        requestDate: Self.requestDate(from: http.allHeaderFields), origin: status.isNotModified ? .cache : .backend)
                let verified = VerifiedHTTPResponse(response: resp, verification: .notRequested)
                completion(.success(verified))
            } catch {
                completion(.failure(.decoding(error as NSError)))
            }
        }.resume()
    }

    private func nextFallbackRequest(_ req: HTTPRequest) -> HTTPRequest? {
        var next = req
        let nextIdx = (next.fallbackIndex ?? -1) + 1
        if nextIdx < next.endpoint.fallbackHosts.count {
            next.fallbackIndex = nextIdx
            return next
        }
        return nil
    }

    private static func requestDate(from headers: [AnyHashable: Any]) -> Date? {
        // 可根据服务端自定义头解析（示例：X-Request-Time: 毫秒）
        if let s = headers["X-Request-Time"] as? String, let ms = UInt64(s) {
            return Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
        }
        return nil
    }
}

// MARK: - AnyEncodable (编码工具)
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init<T: Encodable>(_ base: T) { self.encodeFunc = base.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
