//
//  LoginView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/23.
//


// LoginView.swift
import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginVM()
    @StateObject private var Emailvm = EmailRegisterVM()
    // 如果你没把 GIDClientID 放到 Info.plist，可在这里写：
    private let googleClientID: String? = nil  // "你的 iOS 客户端ID"
    @State private var showRegister = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    // MARK: - 方式1：邮箱/用户名 + 密码
                    GroupBox("账号密码登录") {
                        VStack(spacing: 12) {
                            TextField("邮箱或用户名", text: $vm.identifier)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                                .textContentType(.username)
                                .keyboardType(.emailAddress)
                            SecureField("密码", text: $vm.password)
                                .textContentType(.password)

                            Button {
                                Task { await vm.loginWithPassword() }
                            } label: {
                                HStack {
                                    if vm.isLoading { ProgressView() }
                                    Text("登录")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.identifier.isEmpty || vm.password.isEmpty || vm.isLoading)
                            
                            
                            Button {
                                showRegister.toggle()
                            } label: {
                                HStack {
                                    Text("邮箱注册")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                        }
                    }
                    .sheet(isPresented: $showRegister) {
                        EmailRegisterView(vm: Emailvm)
                    }

                    // MARK: - 方式2：Google
                    GroupBox("第三方登录") {
                        VStack(spacing: 12) {
                            GoogleSignInButtonView(clientID: googleClientID) { result in
                                switch result {
                                case .success(let idToken):
                                    Task { await vm.loginWithGoogle(idToken: idToken) }
                                case .failure(let err):
                                    vm.errorMessage = err.localizedDescription
                                }
                            }
                            AppleSignInButtonView { result in
                                switch result {
                                case .success(let identityToken):
                                    Task { await vm.loginWithApple(identityToken: identityToken) }
                                case .failure(let err):
                                    vm.errorMessage = err.localizedDescription
                                }
                            }
                        }
                    }

                    // MARK: - 方式3：手机号 + 短信验证码
                    GroupBox("手机号登录（短信验证码）") {
                        VStack(spacing: 12) {
                            TextField("手机号（支持 +86 或本地号）", text: $vm.phone)
                                .keyboardType(.phonePad)

                            HStack(spacing: 12) {
                                TextField("验证码", text: $vm.otp)
                                    .keyboardType(.numberPad)
                                Button(vm.otpCountdown > 0 ? "重发(\(vm.otpCountdown)s)" : "获取验证码") {
                                    Task { await vm.requestOTP() }
                                }
                                .disabled(vm.otpCountdown > 0 || vm.isLoading || vm.phone.isEmpty)
                            }

                            Button {
                                Task { await vm.verifyOTP() }
                            } label: {
                                HStack {
                                    if vm.isLoading { ProgressView() }
                                    Text("验证并登录")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.phone.isEmpty || vm.otp.count != 6 || vm.isLoading)
                        }
                    }

                    if let msg = vm.errorMessage {
                        Text(msg).foregroundColor(.red).padding(.top, 4)
                    }

                }
                .padding()
                
                EntryView()
            }
            .navigationTitle("登录")
            .alert("登录成功", isPresented: $vm.loggedIn) {
                Button("好的") { /* 关闭/跳转主页 */ }
            } message: {
                Text("Token 已保存，可直接访问受保护接口。")
            }
        }
    }
}
