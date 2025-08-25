//
//  LoginVM.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/23.
//


// LoginVM.swift
import SwiftUI

@MainActor
final class LoginVM: ObservableObject {
    // 方式1：账号密码
    @Published var identifier = ""
    @Published var password = ""

    // 方式4：短信
    @Published var phone = ""
    @Published var otp = ""
    @Published var otpRequested = false
    @Published var otpCountdown = 0  // 倒计时（秒）

    // UI 状态
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loggedIn = false

    
    private var timer: Timer?

    func loginWithPassword() async {
        await run {
            try await APIClient.shared.login(username: self.identifier, password: self.password)
        }
    }

    func loginWithGoogle(idToken: String) async {
        await run {
            try await APIClient.shared.loginWithGoogle(idToken: idToken)
        }
    }

    func loginWithApple(identityToken: String) async {
        await run {
            try await APIClient.shared.loginWithApple(identityToken: identityToken)
        }
    }

    func requestOTP() async {
        guard phone.replacingOccurrences(of: " ", with: "").isEmpty == false else {
            errorMessage = "请输入手机号"
            return
        }
        await run {
            try await APIClient.shared.requestOTP(phone: self.phone)
            self.otpRequested = true
            self.startCountdown(60)
        }
    }

    func verifyOTP() async {
        guard otp.count == 6 else {
            errorMessage = "请输入6位验证码"
            return
        }
        await run {
            try await APIClient.shared.verifyOTP(phone: self.phone, code: self.otp)
        }
    }

    private func run(_ block: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await block()
            loggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startCountdown(_ seconds: Int) {
        otpCountdown = seconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            if self.otpCountdown > 0 { self.otpCountdown -= 1 }
            else { t.invalidate() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
  
}

