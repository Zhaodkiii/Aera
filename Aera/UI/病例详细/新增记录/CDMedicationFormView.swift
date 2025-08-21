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
                    medBadge("💊 用药")

                    medCard {
                        medHeader(icon: "calendar", title: "基本信息")

                        gridTwoMed {
                            VStack(alignment: .leading, spacing: 8) {
                                medLabel("日期", required: true)
                                DatePicker("", selection: $form.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .modifier(MedFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                medLabel("时间", required: true)
                                DatePicker("", selection: $form.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .modifier(MedFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                        }

                        medDivider()

                        VStack(alignment: .leading, spacing: 8) {
                            medLabel("标题", required: true)
                            let tErr = form.title.trimmed().isEmpty
                            TextField("请输入记录标题", text: $form.title)
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .focused($focus, equals: .title)
                                .modifier(MedFieldChrome(isFocused: focus == .title, isError: tErr, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            medLabel("详细描述", required: true)
                            let dErr = form.detail.trimmed().isEmpty
                            medTextArea("请输入详细描述...", text: $form.detail, isFocused: focus == .detail, isError: dErr)
                                .focused($focus, equals: .detail)
                        }

                        medDivider()

                        VStack(alignment: .leading, spacing: 8) {
                            medLabel("药物名称")
                            TextField("如：阿司匹林", text: $form.medicationName.orEmpty())
                                .textInputAutocapitalization(.never)
                                .focused($focus, equals: .medicationName)
                                .modifier(MedFieldChrome(isFocused: focus == .medicationName, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            medLabel("用药剂量")
                            TextField("如：100mg", text: $form.dosage.orEmpty())
                                .keyboardType(.numbersAndPunctuation)
                                .textInputAutocapitalization(.never)
                                .focused($focus, equals: .dosage)
                                .modifier(MedFieldChrome(isFocused: focus == .dosage, isError: false, scheme: scheme))
                        }

                        gridTwoMed {
                            VStack(alignment: .leading, spacing: 8) {
                                medLabel("用药频次")
                                Picker(selection: $form.frequency) {
                                    Text("选择频次").tag(Optional<Frequency>.none)
                                    ForEach(Frequency.allCases) { f in
                                        Text(f.rawValue).tag(Optional(f))
                                    }
                                } label: {
                                    HStack { Text(form.frequency?.rawValue ?? "选择频次"); Spacer(); Image(systemName: "chevron.down").opacity(0.5) }
                                }
                                .pickerStyle(.menu)
                                .modifier(MedFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                medLabel("用药期限")
                                TextField("如：7天 / 2周", text: $form.duration.orEmpty())
                                    .textInputAutocapitalization(.never)
                                    .focused($focus, equals: .duration)
                                    .modifier(MedFieldChrome(isFocused: focus == .duration, isError: false, scheme: scheme))
                            }
                        }
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // 固定底部操作条
            VStack {
                Spacer()
                HStack {
                    Button(action: cancelNow) { Text("取消") }
                        .buttonStyle(MedBorderButtonStyle())
                    Button(action: saveNow) { Label("保存记录", systemImage: "check").labelStyle(.titleAndIcon) }
                        .buttonStyle(MedPrimaryButtonStyle())
                        .disabled(!isValid)
                        .opacity(isValid ? 1 : 0.6)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: MedicationTokens.shadow(scheme), radius: 10, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
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
    func combinedDateTime() -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year,.month,.day], from: form.date)
        let t = cal.dateComponents([.hour,.minute,.second], from: form.time)
        var c = DateComponents(); c.year=d.year; c.month=d.month; c.day=d.day; c.hour=t.hour; c.minute=t.minute; c.second=t.second ?? 0
        return cal.date(from: c) ?? form.date
    }
}

// MARK: - View Helpers（独特命名）
private extension CDMedicationFormView {
    @ViewBuilder func medBadge(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(Color.purple.opacity(0.12))
            .foregroundStyle(Color.purple)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder func medCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .padding(16)
            .background(MedicationTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(MedicationTokens.border(scheme), lineWidth: 1))
            .shadow(color: MedicationTokens.shadow(scheme), radius: 12, y: 4)
    }

    @ViewBuilder func medHeader(icon: String, title: String) -> some View { HStack(spacing: 8) { Image(systemName: icon); Text(title).font(.headline) } }

    @ViewBuilder func medDivider() -> some View { Rectangle().fill(MedicationTokens.border(scheme)).frame(height: 1).padding(.vertical, 4) }

    @ViewBuilder func gridTwoMed<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12, content: content)
        #else
        HStack(spacing: 12, content: content)
        #endif
    }

    @ViewBuilder func medLabel(_ text: String, required: Bool = false) -> some View {
        HStack(spacing: 4) { Text(text).font(.subheadline.weight(.medium)); if required { Text("*").foregroundStyle(.red) } }
            .accessibilityLabel(Text(required ? "\(text) 必填" : text))
    }

    func medTextArea(_ placeholder: String, text: Binding<String>, isFocused: Bool, isError: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .frame(minHeight: 100)
                .padding(.horizontal, 10).padding(.vertical, 10)
                .background(MedicationTokens.fieldBG(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isError ? MedicationTokens.error : (isFocused ? MedicationTokens.focus : MedicationTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
                )
                .shadow(color: MedicationTokens.shadow(scheme), radius: isFocused ? 8 : 4, y: 2)
            if text.wrappedValue.isEmpty {
                Text(placeholder).foregroundStyle(.secondary).padding(.top, 14).padding(.leading, 16).allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Field Chrome（统一输入外观）
private struct MedFieldChrome: ViewModifier {
    let isFocused: Bool
    let isError: Bool
    let scheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(MedicationTokens.fieldBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? MedicationTokens.error : (isFocused ? MedicationTokens.focus : MedicationTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
            )
            .shadow(color: MedicationTokens.shadow(scheme), radius: isFocused ? 8 : 4, y: 2)
    }
}

// MARK: - Buttons（风格一致，命名独立）
private struct MedPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.85) : Color.accentColor)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MedBorderButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(MedicationTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(MedicationTokens.border(scheme), lineWidth: 1))
    }
}

//// MARK: - Utils
//private extension String { func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) } }


// MARK: - Preview
struct CDMedicationFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDMedicationFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDMedicationFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}
