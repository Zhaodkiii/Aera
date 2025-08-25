//
//  APIError.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

import Foundation


enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(status: Int, message: String?)
    case decoding(Error)
    case network(Error)
    case emptyToken

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .unauthorized: return "未授权或Token失效"
        case .serverError(let status, let message): return "服务器错误(\(status)): \(message ?? "")"
        case .decoding(let e): return "解析失败: \(e.localizedDescription)"
        case .network(let e): return "网络错误: \(e.localizedDescription)"
        case .emptyToken: return "缺少Token，请先登录"
        }
    }
}

struct APIRequestBuilder {
    static func request(url: URL,
                        method: String = "GET",
                        token: String? = Keychain.loadToken(),
                        body: Encodable? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.attachCommonHeaders()
        if method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        return request
    }
}

/// 轻量 Encodable 包装（便于把任意 Encodable 塞进 httpBody）
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ encodable: Encodable) {
        self._encode = encodable.encode
    }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
