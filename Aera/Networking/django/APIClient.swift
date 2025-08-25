//
//  APIClient.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        // 如需日期转化，可配置 dateDecodingStrategy
        return d
    }()

    // MARK: - 登录获取 Token
    struct LoginRequest: Codable {
        let username: String
        let password: String
    }
    struct LoginResponse: Codable { let token: String }

    func login(username: String, password: String) async throws {
        var req = URLRequest(url: APIConfig.tokenEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        req.attachCommonHeaders()
        req.httpBody = try JSONEncoder().encode(LoginRequest(username: username, password: password))

        do {
//            let (data, resp) = try await URLSession.shared.data(for: req)
//            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
//            guard code == 200 else {
//                let msg = String(data: data, encoding: .utf8)
//                if code == 400 || code == 401 { throw APIError.unauthorized }
//                throw APIError.serverError(status: code, message: msg)
//            }
            let data = try await loginWithPassword(identifier: username, password: password)
            let model = try decoder.decode(LoginResponse.self, from: data)
            try Keychain.saveToken(model.token)
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.network(error)
        }
    }
    
    struct PasswordLoginReq: Encodable { let identifier: String; let password: String }

    func loginWithPassword(identifier: String, password: String) async throws -> Data {
        var req = URLRequest(url: APIConfig.loginWithPassword)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "X-Bundle-ID")
        req.setValue(DeviceID.get(), forHTTPHeaderField: "X-Device-ID") // 若已实现
        req.httpBody = try JSONEncoder().encode(PasswordLoginReq(identifier: identifier, password: password))
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "API", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "登录失败"])
        }
        return data
    }

    // MARK: - 列表（分页 + 搜索 + 排序 + 过滤）
    /// - Parameters:
    ///   - search: 模糊搜索（patient_name/diagnosis/chief_complaint/notes）
    ///   - ordering: 例如 "age" / "-visit_date"
    ///   - status: 过滤状态，如 "治疗中"
    ///   - severity: "low"|"medium"|"high"
    ///   - visitDateGTE / visitDateLTE: 日期范围过滤（YYYY-MM-DD）
    ///   - page / pageSize: 分页
    func fetchCases(search: String? = nil,
                    ordering: String? = nil,
                    status: String? = nil,
                    severity: String? = nil,
                    visitDateGTE: String? = nil,
                    visitDateLTE: String? = nil,
                    page: Int = 1,
                    pageSize: Int = 10) async throws -> PageResponse<CaseDTO> {
        guard let token = Keychain.loadToken() else { throw APIError.emptyToken }

        var comps = URLComponents(url: APIConfig.casesBase, resolvingAgainstBaseURL: true)!
        var qs: [URLQueryItem] = [
            .init(name: "page", value: String(page)),
            .init(name: "page_size", value: String(pageSize))
        ]
        if let search, !search.isEmpty { qs.append(.init(name: "search", value: search)) }
        if let ordering, !ordering.isEmpty { qs.append(.init(name: "ordering", value: ordering)) }
        if let status, !status.isEmpty { qs.append(.init(name: "status", value: status)) }
        if let severity, !severity.isEmpty { qs.append(.init(name: "severity", value: severity)) }
        if let visitDateGTE { qs.append(.init(name: "visit_date__gte", value: visitDateGTE)) }
        if let visitDateLTE { qs.append(.init(name: "visit_date__lte", value: visitDateLTE)) }
        comps.queryItems = qs

        guard let url = comps.url else { throw APIError.invalidURL }
        var req = try APIRequestBuilder.request(url: url, method: "GET", token: token)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            guard (200..<300).contains(code) else {
                let msg = String(data: data, encoding: .utf8)
                if code == 401 { throw APIError.unauthorized }
                throw APIError.serverError(status: code, message: msg)
            }
            return try decoder.decode(PageResponse<CaseDTO>.self, from: data)
        } catch let e as APIError {
            throw e
        } catch let e as DecodingError {
            throw APIError.decoding(e)
        } catch {
            throw APIError.network(error)
        }
    }

    // MARK: - 创建病例
    func createCase(_ body: CaseDTO) async throws -> CaseDTO {
        guard let token = Keychain.loadToken() else { throw APIError.emptyToken }
        var requestBody = body
        // 注意：创建时 id/created_at/updated_at 由后端生成，可置为 nil
        requestBody = CaseDTO(
            id: nil,
            patient_name: body.patient_name,
            age: body.age,
            gender: body.gender,
            relationship: body.relationship,
            chief_complaint: body.chief_complaint,
            diagnosis: body.diagnosis,
            symptoms: body.symptoms,
            severity: body.severity,
            visit_date: body.visit_date,
            status: body.status,
            medications: body.medications,
            notes: body.notes,
            is_favorite: body.is_favorite,
            created_at: nil,
            updated_at: nil
        )

        let req = try APIRequestBuilder.request(url: APIConfig.casesBase, method: "POST", token: token, body: requestBody)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            let msg = String(data: data, encoding: .utf8)
            if code == 401 { throw APIError.unauthorized }
            throw APIError.serverError(status: code, message: msg)
        }
        return try decoder.decode(CaseDTO.self, from: data)
    }

    // MARK: - 获取详情
    func getCase(id: Int) async throws -> CaseDTO {
        guard let token = Keychain.loadToken() else { throw APIError.emptyToken }
        let url = APIConfig.casesBase.appendingPathComponent("\(id)/")
        let req = try APIRequestBuilder.request(url: url, method: "GET", token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            let msg = String(data: data, encoding: .utf8)
            if code == 401 { throw APIError.unauthorized }
            throw APIError.serverError(status: code, message: msg)
        }
        return try decoder.decode(CaseDTO.self, from: data)
    }

    // MARK: - 更新（PATCH 局部）
    func updateCase(id: Int, patch: [String: Any]) async throws -> CaseDTO {
        guard let token = Keychain.loadToken() else { throw APIError.emptyToken }
        let url = APIConfig.casesBase.appendingPathComponent("\(id)/")
        var req = try APIRequestBuilder.request(url: url, method: "PATCH", token: token)
        req.httpBody = try JSONSerialization.data(withJSONObject: patch, options: [])
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            let msg = String(data: data, encoding: .utf8)
            if code == 401 { throw APIError.unauthorized }
            throw APIError.serverError(status: code, message: msg)
        }
        return try decoder.decode(CaseDTO.self, from: data)
    }

    // MARK: - 删除
    func deleteCase(id: Int) async throws {
        guard let token = Keychain.loadToken() else { throw APIError.emptyToken }
        let url = APIConfig.casesBase.appendingPathComponent("\(id)/")
        let req = try APIRequestBuilder.request(url: url, method: "DELETE", token: token)
        let (_, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            if code == 401 { throw APIError.unauthorized }
            throw APIError.serverError(status: code, message: nil)
        }
    }
}
