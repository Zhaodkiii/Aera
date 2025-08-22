//
//  CDVisitFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI
/// 新增就医页面（CDVisitFormView）- SwiftUI
/// 字段：日期、时间、标题、详细描述、医院名称、科室、就诊类型、医生诊断、治疗方案
/// 风格：与其它表单页保持一致（三层对比、渐变输入、聚焦/错误态、固定底部操作条）
struct CDVisitFormView: View {
    // MARK: - Types
    struct FormData: Equatable {
        var date: Date = Date()
        var time: Date = Date()
        var title: String = ""
        var detail: String = ""
        var hospital: String? = nil
        var department: String? = nil
        var visitType: VisitType? = .outpatient
        var diagnosis: String? = nil
        var treatment: String? = nil
    }

    enum VisitType: String, CaseIterable, Identifiable {
        case outpatient = "门诊"
        case emergency = "急诊"
        case inpatient = "住院"
        case physical = "体检"
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
    enum Field { case title, detail, hospital, department, diagnosis, treatment }

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
                    FormBadge("🏥 就医", color: Color.green)
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
                          label: "医院名称",
                          required: false,
                          placeholder: "如：北京协和医院",
                          text: $form.hospital.orEmpty(),
                          submitLabel: .next,
                          textInputAutocapitalization: .never
                        )
                        FormTextFieldRow(
                          label: "科室",
                          required: false,
                          placeholder: "如：心内科",
                          text: $form.department.orEmpty(),
                          submitLabel: .next,
                          textInputAutocapitalization: .never
                        )

                        FormPicker("就诊类型", selection: $form.visitType, scheme: scheme)

                        FormTextArea("医生诊断",
                                     placeholder: "医生的诊断结果...",
                                     required: false,
                                     text: $form.diagnosis.orEmpty(),
                                     scheme: scheme)
                        
                        
                        FormTextArea("详细描述",
                                     placeholder: "医嘱或治疗方案...",
                                     required: false,
                                     text: $form.treatment.orEmpty(),
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
        .navigationTitle("新增就医")
        .navigationBarTitleDisplayMode(.inline)
        .alert("请完善必填项", isPresented: $showAlert) { Button("好", role: .cancel) {} }
    }
}

// MARK: - Actions
private extension CDVisitFormView {
    var isValid: Bool { !form.title.trimmed().isEmpty && !form.detail.trimmed().isEmpty }

    func saveNow() {
        guard isValid else { showAlert = true; return }
        onSubmit(form); dismiss()
    }
    func cancelNow() { dismiss() }

}

 

// MARK: - Preview
struct CDVisitFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDVisitFormView { _ in } }.preferredColorScheme(.light)
//            NavigationView { CDVisitFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}
