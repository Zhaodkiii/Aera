//
//  CDFollowupFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI

/// 随访记录 - SwiftUI（CDFollowupFormView）
/// 风格：复用全局 DesignTokens / card / sectionHeader / gridTwo / divider / InputFieldChrome / textArea / PrimaryButtonStyle / BorderButtonStyle
/// 命名：随访页专属前缀（follow*）避免与其它页面冲突
struct CDFollowupFormView: View {
    // MARK: - Types
    struct FormData: Equatable {
        var date: Date = Date()
        var time: Date = Date()
        var title: String = ""
        var detail: String = ""
        var method: FollowMethod? = nil
    }

    enum FollowMethod: String, CaseIterable, Identifiable {
        case phone = "电话随访"
        case clinic = "门诊复诊"
        case video = "视频随访"
        case sms = "短信/IM"
        case home = "居家探访"
        var id: String { rawValue }
    }

    // MARK: - Props
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let onSubmit: (FormData) -> Void

    // MARK: - State
    @State private var form: FormData
    @State private var showAlert = false
    @FocusState private var focus: Field?
    enum Field { case title, detail }

    // MARK: - Init
    init(initial: FormData = .init(), onSubmit: @escaping (FormData) -> Void) {
        self._form = State(initialValue: initial)
        self.onSubmit = onSubmit
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            DesignTokens.pageBG(scheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    FormBadge("📞 随访", color: .gray)
                    SymptomCard(scheme: scheme) {
                        SectionTitle(icon: "calendar", text: "基本信息")

                        
                        FormDateTimeRow(date: $form.date, time: $form.time)
                        
                        VisitDivider(color: DesignTokens.border(scheme))

                        FormTextFieldRow(
                          label: "标题",
                          required: true,
                          placeholder: "请输入记录标题",
                          text: $form.title,
                          submitLabel: .next,
                          textInputAutocapitalization: .never
                        )
                        
                        
                        FormTextArea("详细描述",
                                     placeholder: "请输入详细描述...a",
                                     required: true,
                                     text: $form.detail,
                                     scheme: scheme)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("随访方式")
                            Picker(selection: $form.method) {
                                Text("选择随访方式").tag(Optional<FollowMethod>.none)
                                ForEach(FollowMethod.allCases) { m in
                                    Text(m.rawValue).tag(Optional(m))
                                }
                            } label: {
                                HStack {
                                    Text(form.method?.rawValue ?? "选择随访方式")
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.down").opacity(0.5)
                                }
                            }
                            .pickerStyle(.menu)
                            .modifier(InputFieldChrome(isFocused: false, isError: false, scheme: scheme))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

        }
        .formBottomBarOverlay(
            isValid: isValid,
          saveTitle: "保存记录",
          saveSystemImage: "check",
          onCancel: cancelNow,
          onSave: saveNow
        )
        
        .navigationTitle("新增随访")
        .navigationBarTitleDisplayMode(.inline)
        .alert("请完善必填项", isPresented: $showAlert) { Button("好", role: .cancel) {} }
    }
}

// MARK: - Actions
private extension CDFollowupFormView {
    var isValid: Bool { !form.title.trimmed().isEmpty && !form.detail.trimmed().isEmpty }

    func saveNow() {
        guard isValid else { showAlert = true; return }
        onSubmit(form); dismiss()
    }
    func cancelNow() { dismiss() }

    func combinedDateTime() -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year,.month,.day], from: form.date)
        let t = cal.dateComponents([.hour,.minute,.second], from: form.time)
        var c = DateComponents(); c.year=d.year; c.month=d.month; c.day=d.day; c.hour=t.hour; c.minute=t.minute; c.second=t.second ?? 0
        return cal.date(from: c) ?? form.date
    }
}


// MARK: - Preview
struct CDFollowupFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDFollowupFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDFollowupFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}


