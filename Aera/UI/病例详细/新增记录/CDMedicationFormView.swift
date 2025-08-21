//
//  CDMedicationFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI

// MARK: - Medication Design Tokens（与其它表单风格一致，命名独立）
private enum MedicationTokens {
    static func pageBG(_ scheme: ColorScheme) -> Color { scheme == .dark ? .black : Color(UIColor.systemGroupedBackground) }
    static func cardBG(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(UIColor.secondarySystemBackground) : .white }
    static func fieldBG(_ scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
        ? LinearGradient(colors: [Color(white: 0.14), Color(white: 0.10)], startPoint: .top, endPoint: .bottom)
        : LinearGradient(colors: [Color(white: 0.98), Color(white: 0.96)], startPoint: .top, endPoint: .bottom)
    }
    static func border(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08) }
    static func shadow(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.08) }
    static let focus = Color.accentColor
    static let error = Color(.systemRed)
}

/// 用药记录 - SwiftUI（CDMedicationFormView）
/// 字段：日期、时间、标题、详细描述、药物名称、剂量、频次（下拉）、用药期限（天）
struct CDMedicationFormView: View {
    // MARK: - Types
    struct FormData: Equatable {
        var date: Date = Date()
        var time: Date = Date()
        var title: String = ""
        var detail: String = ""
        var medicationName: String? = nil
        var dosage: String? = nil
        var frequency: Frequency? = nil
        var duration: String? = nil // 例如 “7天”/“2周” 或直接数字
    }

    enum Frequency: String, CaseIterable, Identifiable {
        case qd = "每日一次"
        case bid = "每日两次"
        case tid = "每日三次"
        case qod = "隔日一次"
        case weekly = "每周一次"
        case prn = "按需"
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
    enum Field { case title, detail, medicationName, dosage, duration }

    init(initial: FormData = .init(), onSubmit: @escaping (FormData) -> Void) {
        self._form = State(initialValue: initial)
        self.onSubmit = onSubmit
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            MedicationTokens.pageBG(scheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    FormBadge("💊 用药", color: .purple)
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
                            FormLabel("用药剂量")
                            TextField("如：100mg", text: $form.dosage.orEmpty())
                                .keyboardType(.numbersAndPunctuation)
                                .textInputAutocapitalization(.never)
                                .focused($focus, equals: .dosage)
                                .inputFieldChrome(isFocused: false, isError: false, scheme: scheme)
                        }

                        GridTwo {
                            VStack(alignment: .leading, spacing: 8) {
                                FormLabel("用药频次")
                                Picker(selection: $form.frequency) {
                                    Text("选择频次").tag(Optional<Frequency>.none)
                                    ForEach(Frequency.allCases) { f in
                                        Text(f.rawValue).tag(Optional(f))
                                    }
                                } label: {
                                    HStack { Text(form.frequency?.rawValue ?? "选择频次"); Spacer(); Image(systemName: "chevron.down").opacity(0.5) }
                                }
                                .pickerStyle(.menu)
                                .inputFieldChrome(isFocused: false, isError: false, scheme: scheme)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                FormLabel("用药期限")
                                TextField("如：7天 / 2周", text: $form.duration.orEmpty())
                                    .textInputAutocapitalization(.never)
                                    .focused($focus, equals: .duration)
                                    .inputFieldChrome(isFocused: false, isError: false, scheme: scheme)
                            }
                        }
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
        .navigationTitle("新增用药")
        .navigationBarTitleDisplayMode(.inline)
        .alert("请完善必填项", isPresented: $showAlert) { Button("好", role: .cancel) {} }
    }
}

// MARK: - Actions
private extension CDMedicationFormView {
    var isValid: Bool { !form.title.trimmed().isEmpty && !form.detail.trimmed().isEmpty }
    func saveNow() { guard isValid else { showAlert = true; return }; onSubmit(form); dismiss() }
    func cancelNow() { dismiss() }

}

// MARK: - Preview
struct CDMedicationFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDMedicationFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDMedicationFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}
