//
//  EmailRegisterVM.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/23.
//


import Foundation
import Combine

@MainActor
final class EmailRegisterVM: ObservableObject {
    @Published var email: String = ""
    @Published var code: String = ""
    @Published var password: String = ""
    @Published var username: String = ""
    @Published var confirm: String = ""
    @Published var isSending = false
    @Published var isVerifying = false
    @Published var isRegistering = false
    @Published var step: Step = .enterEmail
    @Published var error: String?
    @Published var toast: String?

    enum Step { case enterEmail, enterCode, setPassword }

    private let api: APIClient
    init() {
        self.api = APIClient.shared
    }

    // 发送验证码
    func sendCode() async {
        guard email.isValidEmail else { error = "请输入正确邮箱"; return }
        error = nil; isSending = true
        defer { isSending = false }
        do {
            try await api.requestEmailOTP(email: email)
            toast = "验证码已发送到邮箱"
            step = .enterCode
        } catch {
            self.error = friendly(error)
        }
    }

    // 验证验证码
    func verifyCode() async {
        guard !code.isEmpty else { error = "请输入验证码"; return }
        error = nil; isVerifying = true
        defer { isVerifying = false }
        do {
            try await api.verifyEmailOTP(email: email, code: code)
            toast = "邮箱验证成功"
            step = .setPassword
        } catch {
            self.error = friendly(error)
        }
    }
    func register() async {
        guard password.count >= 6 else { error = "密码至少 6 位"; return }
        guard password == confirm else { error = "两次输入的密码不一致"; return }
        error = nil; isRegistering = true
        defer { isRegistering = false }
        do {
            let uname = username.isEmpty ? nil : username
            let auth = try await api.registerWithEmail(email: email, password: password, username: uname)
            try Keychain.saveToken(auth.token)
            toast = "注册成功"
        } catch {
            self.error = friendly(error)
        }
    }

    private func friendly(_ error: Error) -> String {
        (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String
        ?? "网络错误，请稍后重试"
    }
}
 extension String {
    var isValidEmail: Bool {
        // 简易校验，够用了；严谨可用 NSDataDetector
        contains("@") && contains(".") && count >= 5
    }
}
// 1) 定义两种可能的服务端返回形状
struct AuthResponseV2: Decodable { // 你之前设计的
    let token: String
    struct User: Decodable { let id: Int; let username: String; let email: String? }
    let user: User
    let bundle_id: String?
}

struct AuthResponseV1Flat: Decodable { // 实际返回的扁平结构
    let id: Int
    let username: String
    let email: String?
    let first_name: String?
    let last_name: String?
    let token: String
}

// 2) 统一到一个客户端内部使用的模型
struct AuthUnified {
    let token: String
    let userID: Int
    let username: String
    let email: String?
    let bundleID: String?
}

// 3) 兼容解析函数
func decodeAuthUnified(_ data: Data) throws -> AuthUnified {
    let dec = JSONDecoder()

    if let v2 = try? dec.decode(AuthResponseV2.self, from: data) {
        return AuthUnified(
            token: v2.token,
            userID: v2.user.id,
            username: v2.user.username,
            email: v2.user.email,
            bundleID: v2.bundle_id
        )
    }
    if let v1 = try? dec.decode(AuthResponseV1Flat.self, from: data) {
        return AuthUnified(
            token: v1.token,
            userID: v1.id,
            username: v1.username,
            email: v1.email,
            bundleID: nil
        )
    }
    // 都不符合时，抛出更可读的错误
    let text = String(data: data, encoding: .utf8) ?? "<non-utf8>"
    throw NSError(domain: "API", code: -2, userInfo: [NSLocalizedDescriptionKey: "注册响应解析失败：\(text)"])
}
