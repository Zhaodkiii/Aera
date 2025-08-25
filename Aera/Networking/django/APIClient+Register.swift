//
//  APIClient+Register.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

// APIClient+Register.swift
import Foundation

extension APIClient {
    struct RegisterRequest: Codable {
        let username: String
        let password: String
        let email: String?
        let first_name: String?
        let last_name: String?
    }

    struct RegisterResponse: Codable {
        let id: Int
        let username: String
        let email: String?
        let first_name: String?
        let last_name: String?
        let token: String
    }

    func register(username: String,
                  password: String,
                  email: String? = nil,
                  firstName: String? = nil,
                  lastName: String? = nil) async throws {
        let url = URL(string: "/api/auth/register/", relativeTo: APIConfig.baseURL)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = RegisterRequest(username: username,
                                   password: password,
                                   email: email,
                                   first_name: firstName,
                                   last_name: lastName)
        req.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            guard (200..<300).contains(code) else {
                let msg = String(data: data, encoding: .utf8)
                if code == 400 || code == 401 { throw APIError.unauthorized }
                throw APIError.serverError(status: code, message: msg)
            }
            let model = try JSONDecoder().decode(RegisterResponse.self, from: data)
            try Keychain.saveToken(model.token) // 注册成功后直接保存 Token
        } catch let e as APIError {
            throw e
        } catch let e as DecodingError {
            throw APIError.decoding(e)
        } catch {
            throw APIError.network(error)
        }
    }
}
