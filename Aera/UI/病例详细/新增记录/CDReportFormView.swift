//
//  CDReportFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI
import SwiftUI
import SwiftUI


/// 检查报告表单 - SwiftUI
/// 改进点：
/// 1) 页面与卡片与输入框三层对比；2) 输入框使用渐变底色、阴影和边框，聚焦/错误态强化；
/// 3) 细化排版：分组间距、分隔线、顶区徽章；4) 固定底部操作区（可选）。
struct CDReportFormView: View {
    // MARK: - Types
    struct FormData: Equatable {
        var date: Date = Date()
        var time: Date = Date()
        var title: String = ""
        var detail: String = ""
        var reportName: String? = nil
        var checkType: CheckType? = .bUltrasound
        var conclusion: String? = nil
        var doctorAdvice: String? = nil
    }

    enum CheckType: String, CaseIterable, Identifiable {
        case bUltrasound = "B超"
        case ct = "CT"
        case mri = "核磁共振"
        case blood = "血常规"
        case urine = "尿常规"
        case ecg = "心电图"
        case other = "其他"
        var id: String { rawValue }
    }

    // MARK: - Props
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let onSubmit: (FormData) -> Void

    // MARK: - State
    @State private var form: FormData
    @State private var showAlert = false
    @FocusState private var focusedField: Field?
    enum Field { case title, detail, reportName, conclusion, doctorAdvice }

    // MARK: - Init
    init(initial: FormData = .init(), onSubmit: @escaping (FormData) -> Void) {
        self._form = State(initialValue: initial)
        self.onSubmit = onSubmit
    }

    var body: some View {
        ZStack {
            DesignTokens.pageBG(scheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    FormBadge("📄 检查报告", color: .accentColor)
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

                        VisitDivider(color: DesignTokens.border(scheme))

                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("报告名称")
                            TextField("如：血常规检查报告", text: $form.reportName.orEmpty())
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .reportName)
                                .modifier(InputFieldChrome(isFocused: focusedField == .reportName, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            FormLabel("检查类型")
                            Picker(selection: $form.checkType) {
                                Text("未选择").tag(Optional<CheckType>.none)
                                ForEach(CheckType.allCases) { t in
                                    Text(t.rawValue).tag(Optional(t))
                                }
                            } label: {
                                HStack { Text(form.checkType?.rawValue ?? "选择类型"); Spacer(); Image(systemName: "chevron.down").opacity(0.5) }
                            }
                            .pickerStyle(.menu)
                            .modifier(InputFieldChrome(isFocused: false, isError: false, scheme: scheme))
                        }

                        FormTextArea("检查结论",
                                     placeholder: "检查结论...",
                                     required: false,
                                     text: $form.conclusion.orEmpty(),
                                     scheme: scheme)
                        
                        FormTextArea("医生建议",
                                     placeholder: "医生建议或注意事项...",
                                     required: false,
                                     text: $form.doctorAdvice.orEmpty(),
                                     scheme: scheme)

                        
                    }

                    Spacer(minLength: 16)
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
        .navigationTitle("新增检查记录")
        .navigationBarTitleDisplayMode(.inline)
        .alert("请完善必填项", isPresented: $showAlert) { Button("好", role: .cancel) { } }
    }
}

// MARK: - Actions
private extension CDReportFormView {
    var isValid: Bool { !form.title.trimmed().isEmpty && !form.detail.trimmed().isEmpty }

    func saveNow() {
        guard isValid else { showAlert = true; return }
        onSubmit(form); dismiss()
    }
    func cancelNow() { dismiss() }

}

// MARK: - Preview
struct CDReportFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDReportFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDReportFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}

