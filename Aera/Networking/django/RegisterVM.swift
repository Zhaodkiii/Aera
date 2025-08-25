//
//  RegisterVM.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//


// RegisterView.swift
import SwiftUI

@MainActor
final class RegisterVM: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRegistered = false

    var canSubmit: Bool {
        !username.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        (email.isEmpty || email.contains("@"))
    }

    func submit() async {
        guard canSubmit else {
            errorMessage = "请检查输入：用户名必填、密码至少8位且两次一致、邮箱格式正确。"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await APIClient.shared.register(
                username: username.trimmingCharacters(in: .whitespaces),
                password: password,
                email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName
            )
            isRegistered = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct RegisterView: View {
    @StateObject private var vm = RegisterVM()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("账户信息")) {
                    TextField("用户名（必填）", text: $vm.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("邮箱（可选）", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        TextField("名（可选）", text: $vm.firstName)
                        TextField("姓（可选）", text: $vm.lastName)
                    }
                }

                Section(header: Text("设置密码"),
                        footer: VStack(alignment: .leading, spacing: 6) {
                            Text("密码至少 8 位，建议包含大小写、数字与符号。")
                            if !vm.confirmPassword.isEmpty, vm.password != vm.confirmPassword {
                                Text("两次密码不一致").foregroundColor(.red)
                            }
                        }) {
                    SecureField("密码（必填）", text: $vm.password)
                    SecureField("确认密码（必填）", text: $vm.confirmPassword)
                }

                if let msg = vm.errorMessage {
                    Section {
                        Text(msg).foregroundColor(.red)
                    }
                }

                Section {
                    Button {
                        Task { await vm.submit() }
                    } label: {
                        HStack {
                            if vm.isLoading { ProgressView() }
                            Text("注册并登录")
                        }
                    }
                    .disabled(!vm.canSubmit || vm.isLoading)
                }
            }
            .navigationTitle("注册")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("注册成功", isPresented: $vm.isRegistered) {
                Button("好的") { dismiss() }
            } message: {
                Text("已自动登录，可直接使用其他接口。")
            }
        }
    }
}