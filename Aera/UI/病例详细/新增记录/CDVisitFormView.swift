//
//  CDVisitFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI

// MARK: - Visit Design Tokens（独立于其它页面，但风格保持一致）
private enum VisitTokens {
    static func pageBG(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    static func cardBG(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    static func fieldBG(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark { return LinearGradient(colors: [Color(white: 0.14), Color(white: 0.10)], startPoint: .top, endPoint: .bottom) }
        return LinearGradient(colors: [Color(white: 0.98), Color(white: 0.96)], startPoint: .top, endPoint: .bottom)
    }
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    static func shadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.08)
    }
    static let focus = Color.accentColor
    static let error = Color(.systemRed)
}

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
            VisitTokens.pageBG(scheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    visitBadge("🩺 就医")

                    visitCard {
                        visitHeader(icon: "calendar", title: "基本信息")

                        gridTwoVisit {
                            VStack(alignment: .leading, spacing: 8) {
                                visitLabel("日期", required: true)
                                DatePicker("", selection: $form.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .modifier(VisitFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                visitLabel("时间", required: true)
                                DatePicker("", selection: $form.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .modifier(VisitFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                        }

                        visitDivider()

                        VStack(alignment: .leading, spacing: 8) {
                            visitLabel("标题", required: true)
                            let titleError = form.title.trimmed().isEmpty
                            TextField("请输入记录标题", text: $form.title)
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .focused($focus, equals: .title)
                                .modifier(VisitFieldChrome(isFocused: focus == .title, isError: titleError, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            visitLabel("详细描述", required: true)
                            let detailError = form.detail.trimmed().isEmpty
                            visitTextArea("请输入详细描述...", text: $form.detail, isFocused: focus == .detail, isError: detailError)
                                .focused($focus, equals: .detail)
                        }

                        visitDivider()

                        VStack(alignment: .leading, spacing: 8) {
                            visitLabel("医院名称")
                            TextField("如：北京协和医院", text: $form.hospital.orEmpty())
                                .textInputAutocapitalization(.never)
                                .focused($focus, equals: .hospital)
                                .modifier(VisitFieldChrome(isFocused: focus == .hospital, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            visitLabel("科室")
                            TextField("如：心内科", text: $form.department.orEmpty())
                                .textInputAutocapitalization(.never)
                                .focused($focus, equals: .department)
                                .modifier(VisitFieldChrome(isFocused: focus == .department, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            visitLabel("就诊类型")
                            Picker(selection: $form.visitType) {
                                Text("选择就诊类型").tag(Optional<VisitType>.none)
                                ForEach(VisitType.allCases) { t in
                                    Text(t.rawValue).tag(Optional(t))
                                }
                            } label: {
                                HStack {
                                    Text(form.visitType?.rawValue ?? "选择就诊类型")
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.down").opacity(0.5)
                                }
                            }
                            .pickerStyle(.menu)
                            .modifier(VisitFieldChrome(isFocused: false, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            visitLabel("医生诊断")
                            visitTextArea("医生的诊断结果...", text: $form.diagnosis.orEmpty(), isFocused: focus == .diagnosis, isError: false)
                                .focused($focus, equals: .diagnosis)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            visitLabel("治疗方案")
                            visitTextArea("医嘱或治疗方案...", text: $form.treatment.orEmpty(), isFocused: focus == .treatment, isError: false)
                                .focused($focus, equals: .treatment)
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
                        .buttonStyle(VisitBorderButtonStyle())
                    Button(action: saveNow) {
                        Label("保存记录", systemImage: "check").labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(VisitPrimaryButtonStyle())
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.6)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: VisitTokens.shadow(scheme), radius: 10, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
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

    func combinedDateTime() -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year,.month,.day], from: form.date)
        let t = cal.dateComponents([.hour,.minute,.second], from: form.time)
        var c = DateComponents(); c.year=d.year; c.month=d.month; c.day=d.day; c.hour=t.hour; c.minute=t.minute; c.second=t.second ?? 0
        return cal.date(from: c) ?? form.date
    }
}

// MARK: - View Helpers（独特命名，避免与其它页面冲突）
private extension CDVisitFormView {
    @ViewBuilder func visitBadge(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(Color.green.opacity(0.12))
            .foregroundStyle(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder func visitCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .padding(16)
            .background(VisitTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(VisitTokens.border(scheme), lineWidth: 1))
            .shadow(color: VisitTokens.shadow(scheme), radius: 12, y: 4)
    }

    @ViewBuilder func visitHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) { Image(systemName: icon); Text(title).font(.headline) }
    }

    @ViewBuilder func visitDivider() -> some View { Rectangle().fill(VisitTokens.border(scheme)).frame(height: 1).padding(.vertical, 4) }

    @ViewBuilder func gridTwoVisit<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12, content: content)
        #else
        HStack(spacing: 12, content: content)
        #endif
    }

    @ViewBuilder func visitLabel(_ text: String, required: Bool = false) -> some View {
        HStack(spacing: 4) { Text(text).font(.subheadline.weight(.medium)); if required { Text("*").foregroundStyle(.red) } }
            .accessibilityLabel(Text(required ? "\(text) 必填" : text))
    }

    func visitTextArea(_ placeholder: String, text: Binding<String>, isFocused: Bool, isError: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .frame(minHeight: 100)
                .padding(.horizontal, 10).padding(.vertical, 10)
                .background(VisitTokens.fieldBG(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isError ? VisitTokens.error : (isFocused ? VisitTokens.focus : VisitTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
                )
                .shadow(color: VisitTokens.shadow(scheme), radius: isFocused ? 8 : 4, y: 2)
            if text.wrappedValue.isEmpty {
                Text(placeholder).foregroundStyle(.secondary).padding(.top, 14).padding(.leading, 16).allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Field Chrome（统一输入外观）
private struct VisitFieldChrome: ViewModifier {
    let isFocused: Bool
    let isError: Bool
    let scheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(VisitTokens.fieldBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? VisitTokens.error : (isFocused ? VisitTokens.focus : VisitTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
            )
            .shadow(color: VisitTokens.shadow(scheme), radius: isFocused ? 8 : 4, y: 2)
    }
}

// MARK: - Buttons（与其它页一致，但命名独立）
private struct VisitPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.85) : Color.accentColor)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct VisitBorderButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(VisitTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(VisitTokens.border(scheme), lineWidth: 1))
    }
}
//
//// MARK: - Utils
//private extension String { func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) } }
 

// MARK: - Preview
struct CDVisitFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDVisitFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDVisitFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}
