//
//  CDSymptomFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

/// 新增症状 - SwiftUI（风格与 CDReportFormView 保持一致，命名保持独特）
struct CDSymptomFormView: View {
    // MARK: - Types
    struct FormData: Equatable {
        var date: Date = Date()
        var time: Date = Date()
        var title: String = ""
        var detail: String = ""
        var severity: Severity? = nil
    }

    enum Severity: String, CaseIterable, Identifiable {
        case mild = "🙂 轻度"
        case moderate = "😕 中度"
        case severe = "😣 重度"
        case critical = "🆘 危重"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .mild: return "🙂"
            case .moderate: return "😕"
            case .severe: return "😣"
            case .critical: return "🆘"
            }
        }
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
                    FormBadge("🤒 症状", color: .orange)
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
                        
                        FormPicker("症状严重程度", selection: $form.severity, scheme: scheme)

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
        .navigationTitle("新增症状")
        .navigationBarTitleDisplayMode(.inline)
        .alert("请完善必填项", isPresented: $showAlert) { Button("好", role: .cancel) {} }
    }
}

// MARK: - Actions
private extension CDSymptomFormView {
    var isValid: Bool { !form.title.trimmed().isEmpty && !form.detail.trimmed().isEmpty }

    func saveNow() {
        guard isValid else { showAlert = true; return }
        onSubmit(form); dismiss()
    }
    func cancelNow() { dismiss() }

}

// MARK: - Preview
struct CDSymptomFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDSymptomFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDSymptomFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}

