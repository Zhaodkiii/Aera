//
//  CDSurgeryFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI

/// 手术记录 - SwiftUI（CDSurgeryFormView）
/// 设计：沿用项目既有的 DesignTokens / card / sectionHeader / gridTwo / divider / InputFieldChrome / PrimaryButtonStyle 等，保持整体风格统一；
/// 命名：采用手术页专属方法前缀（surgery*）避免与其它页面冲突。
struct CDSurgeryFormView: View {
    // MARK: - Types
    struct FormData: Equatable {
        var date: Date = Date()
        var time: Date = Date()
        var title: String = ""
        var detail: String = ""
        var surgeryName: String? = nil
        var surgeon: String? = nil
        var anesthesia: Anesthesia? = nil
        var postOpNotes: String? = nil
    }

    enum Anesthesia: String, CaseIterable, Identifiable {
        case general = "全身麻醉"
        case regional = "椎管内麻醉"
        case local = "局部麻醉"
        case sedation = "静脉镇静"
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
    enum Field { case title, detail, surgeryName, surgeon, postOpNotes }

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
                    FormBadge("🔪 手术", color: .red)
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

                        FormTextFieldRow(
                          label: "手术名称",
                          required: false,
                          placeholder: "手术名称",
                          text: $form.surgeryName.orEmpty(),
                          submitLabel: .next,
                          textInputAutocapitalization: .never
                        )
                        FormTextFieldRow(
                          label: "手术医生",
                          required: false,
                          placeholder: "主刀医生姓名",
                          text: $form.surgeon.orEmpty(),
                          submitLabel: .next,
                          textInputAutocapitalization: .never
                        )
                        
                        FormPicker("麻醉方式", selection: $form.anesthesia, scheme: scheme)

                        
                        FormTextArea("术后情况",
                                     placeholder: "手术效果、并发症或注意事项...",
                                     required: false,
                                     text: $form.postOpNotes.orEmpty(),
                                     scheme: scheme)
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
        
        .navigationTitle("新增手术")
        .navigationBarTitleDisplayMode(.inline)
        .alert("请完善必填项", isPresented: $showAlert) { Button("好", role: .cancel) {} }
    }
}

// MARK: - Actions
private extension CDSurgeryFormView {
    var isValid: Bool { !form.title.trimmed().isEmpty && !form.detail.trimmed().isEmpty }
    func saveNow() { guard isValid else { showAlert = true; return }; onSubmit(form); dismiss() }
    func cancelNow() { dismiss() }
}


// MARK: - Preview
struct CDSurgeryFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDSurgeryFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDSurgeryFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}


