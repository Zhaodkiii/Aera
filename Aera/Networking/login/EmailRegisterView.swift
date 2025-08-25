//
//  EmailRegisterView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/23.
//


import SwiftUI

struct EmailRegisterView: View {
    @StateObject var vm: EmailRegisterVM

    var body: some View {
        VStack(spacing: 16) {
            Text("邮箱注册").font(.title2).bold().padding(.top, 8)

            switch vm.step {
            case .enterEmail:
                emailStep
            case .enterCode:
                codeStep
            case .setPassword:
                passwordStep
            }

            if let err = vm.error {
                Text(err).foregroundColor(.red).font(.footnote).multilineTextAlignment(.center)
            }
            if let toast = vm.toast {
                Text(toast).foregroundColor(.green).font(.footnote).multilineTextAlignment(.center)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .animation(.default, value: vm.step)
    }

    private var emailStep: some View {
        VStack(spacing: 12) {
            TextField("邮箱地址", text: $vm.email)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await vm.sendCode() }
            } label: {
                if vm.isSending { ProgressView() } else { Text("发送验证码").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isSending || !vm.email.isValidEmail)
        }
    }

    private var codeStep: some View {
        VStack(spacing: 12) {
            HStack {
                Text(vm.email).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Button("修改邮箱") { vm.step = .enterEmail }
            }
            TextField("邮箱验证码", text: $vm.code)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await vm.verifyCode() }
            } label: {
                if vm.isVerifying { ProgressView() } else { Text("验证邮箱").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isVerifying || vm.code.isEmpty)
            Button("重新发送验证码") {
                Task { await vm.sendCode() }
            }.disabled(vm.isSending)
        }
    }

    private var passwordStep: some View {
        VStack(spacing: 12) {
            TextField("用户名（可留空自动生成）", text: $vm.username)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            SecureField("设置密码（至少 6 位）", text: $vm.password)
                .textFieldStyle(.roundedBorder)
            SecureField("确认密码", text: $vm.confirm)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await vm.register() }
            } label: {
                if vm.isRegistering { ProgressView() } else { Text("提交注册").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isRegistering || vm.password.count < 6 || vm.password != vm.confirm)
        }
    }
}
