//
//  NetworkError.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/18.
//

import Foundation

// MARK: - 统一错误
enum NetworkError: Error, CustomStringConvertible {
    case decoding(NSError)
    case networkError(NSError)
    case dnsError(failedURL: URL, resolvedHost: String?)
    case unableToCreateRequest(path: String)
    case unexpectedResponse(URLResponse?)
    case errorResponse(ErrorResponse, HTTPStatusCode)

    var description: String {
        switch self {
        case .decoding(let e): return "Decoding error: \(e.localizedDescription)"
        case .networkError(let e): return "Transport error: \(e.localizedDescription)"
        case .dnsError(let url, let ip): return "Blocked by DNS/hosts? \(url.absoluteString) -> \(ip ?? "nil")"
        case .unableToCreateRequest(let path): return "Build request failed: \(path)"
        case .unexpectedResponse(let r): return "Unexpected response: \(String(describing: r))"
        case .errorResponse(let er, let code): return "Backend error [\(code.raw)]: \(er.message ?? "no message")"
        }
    }
}

// MARK: - 后端错误模型
struct ErrorResponse: Decodable, Equatable {
    var code: Int
    var message: String?
    var attributeErrors: [String: String]?

    static func from(data: Data, headers: [AnyHashable: Any], fallbackStatus: Int) -> ErrorResponse {
        if let obj = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return obj
        }
        // 也可尝试 wrapper 字段等，此处简化
        return ErrorResponse(code: fallbackStatus, message: String(data: data, encoding: .utf8), attributeErrors: nil)
    }
}

// MARK: - DNS 拦截识别（简化版）
protocol DNSCheckerType {
    static func errorWithBlockedHost(from error: Error) -> NetworkError
}
enum DNSChecker: DNSCheckerType {
    static let invalidHosts: Set<String> = ["0.0.0.0", "127.0.0.1"]
    static func errorWithBlockedHost(from error: Error) -> NetworkError {
        let ns = error as NSError
        guard ns.domain == NSURLErrorDomain,
              ns.code == NSURLErrorCannotConnectToHost,
              let url = ns.userInfo[NSURLErrorFailingURLErrorKey] as? URL,
              let host = url.host
        else { return .networkError(ns) }

        // 极简：尝试解析 IP（演示用，真实可用 getaddrinfo / NWPathMonitor）
        if invalidHosts.contains(host) {
            return .dnsError(failedURL: url, resolvedHost: host)
        }
        return .networkError(ns)
    }
}
