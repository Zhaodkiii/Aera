//
//  APIClient+Auth.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/23.
//

// APIClient+Auth.swift
import Foundation
import AuthenticationServices // 仅为类型别名，无 AS 也可删


import Foundation

import Foundation

extension URLRequest {
    mutating func attachCommonHeaders() {
        self.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "X-Bundle-ID")
        let permanentID = DeviceID.get()

        self.setValue(permanentID, forHTTPHeaderField: "X-Device-ID")
    }
}
extension APIClient {
    // MARK: - DTOs
    struct EmailOTPRequest: Encodable { let email: String }
    struct EmailOTPVerify: Encodable { let email: String; let code: String }
    struct EmailRegisterReq: Encodable {
        let email: String
        let password: String
        let username: String?   // ← 新增
    }
    struct AuthResponse: Decodable {
        let token: String
        struct User: Decodable { let id: Int; let username: String; let email: String? }
        let user: User
        let bundle_id: String?
    }

    // MARK: - Helpers
    private func makeJSONRequest(_ url: URL, method: String = "POST") -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bid = Bundle.main.bundleIdentifier {
            req.setValue(bid, forHTTPHeaderField: "X-Bundle-ID")
        }
        return req
    }

    // MARK: - Email OTP
    func requestEmailOTP(email: String) async throws {
                let url = URL(string: "/api/auth/email/otp/request/", relativeTo: APIConfig.baseURL)!

        var req = makeJSONRequest(url)
        req.httpBody = try JSONEncoder().encode(EmailOTPRequest(email: email))
        _ = try await URLSession.shared.data(for: req)
    }

    func verifyEmailOTP(email: String, code: String) async throws {
//        let url = baseURL.appendingPathComponent("/api/auth/email/otp/verify/")
                let url = URL(string: "/api/auth/email/otp/verify/", relativeTo: APIConfig.baseURL)!

        var req = makeJSONRequest(url)
        req.httpBody = try JSONEncoder().encode(EmailOTPVerify(email: email, code: code))
        _ = try await URLSession.shared.data(for: req)
    }

    // MARK: - Register (email + password) — 需要后端已要求邮箱先通过 OTP 验证
    func registerWithEmail(email: String, password: String, username: String?) async throws -> AuthUnified {
        let url = URL(string: "/api/auth/register/", relativeTo: APIConfig.baseURL)!
        var req = makeJSONRequest(url)
        struct Req: Encodable { let email: String; let password: String; let username: String? }
        req.httpBody = try JSONEncoder().encode(Req(email: email, password: password, username: username))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try checkHTTP(resp: resp, data: data)  // 201 属于 2xx，会通过
        return try decodeAuthUnified(data)
    }

    // 简单的 HTTP 错误检查
    private func checkHTTP(resp: URLResponse, data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        if (200..<300).contains(http.statusCode) { return }
        let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
        throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}

extension APIClient {
//    // MARK: - 账号密码登录（邮箱/用户名）
//    struct PasswordLoginRequest: Codable {
//        let identifier: String
//        let password: String
//    }
    struct LoginUser: Codable { let id: Int; let username: String; let email: String? }
    struct TokenResponse: Codable { let token: String; let user: LoginUser? }
//

    // MARK: - Google 登录
    struct GoogleLoginRequest: Codable { let id_token: String }
    func loginWithGoogle(idToken: String) async throws {
        let url = URL(string: "/api/auth/login/google/", relativeTo: APIConfig.baseURL)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.attachCommonHeaders()
        req.httpBody = try JSONEncoder().encode(GoogleLoginRequest(id_token: idToken))

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            let msg = String(data: data, encoding: .utf8)
            if code == 400 || code == 401 { throw APIError.unauthorized }
            throw APIError.serverError(status: code, message: msg)
        }
        let model = try JSONDecoder().decode(TokenResponse.self, from: data)
        try Keychain.saveToken(model.token)
    }

    // MARK: - Apple 登录
    struct AppleLoginRequest: Codable { let identity_token: String }
    func loginWithApple(identityToken: String) async throws {
        let url = URL(string: "/api/auth/login/apple/", relativeTo: APIConfig.baseURL)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.attachCommonHeaders()
        req.httpBody = try JSONEncoder().encode(AppleLoginRequest(identity_token: identityToken))

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            let msg = String(data: data, encoding: .utf8)
            if code == 400 || code == 401 { throw APIError.unauthorized }
            throw APIError.serverError(status: code, message: msg)
        }
        let model = try JSONDecoder().decode(TokenResponse.self, from: data)
        try Keychain.saveToken(model.token)
    }

    // MARK: - 短信验证码
    struct OTPRequest: Codable { let phone: String }
    struct OTPVerifyRequest: Codable { let phone: String; let code: String }

    func requestOTP(phone: String) async throws {
        let url = URL(string: "/api/auth/otp/request/", relativeTo: APIConfig.baseURL)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.attachCommonHeaders()
        req.httpBody = try JSONEncoder().encode(OTPRequest(phone: phone))
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            let msg = String(data: data, encoding: .utf8)
            throw APIError.serverError(status: code, message: msg)
        }
    }

    func verifyOTP(phone: String, code: String) async throws {
        let url = URL(string: "/api/auth/otp/verify/", relativeTo: APIConfig.baseURL)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.attachCommonHeaders()
        req.httpBody = try JSONEncoder().encode(OTPVerifyRequest(phone: phone, code: code))
        let (data, resp) = try await URLSession.shared.data(for: req)
        let sc = (resp as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(sc) else {
            let msg = String(data: data, encoding: .utf8)
            if sc == 400 || sc == 401 { throw APIError.unauthorized }
            throw APIError.serverError(status: sc, message: msg)
        }
        let model = try JSONDecoder().decode(TokenResponse.self, from: data)
        try Keychain.saveToken(model.token)
    }
}
