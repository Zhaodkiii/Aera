//
//  CDSymptomFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI

// MARK: - Symptom Design Tokens（与报告页一致的三层对比 + 焦点/错误态）
private enum SymptomTokens {
    static func pageBG(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    static func cardBG(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    static func fieldBG(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(colors: [Color(white: 0.14), Color(white: 0.10)], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [Color(white: 0.98), Color(white: 0.96)], startPoint: .top, endPoint: .bottom)
        }
    }
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    static func subtleShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.08)
    }
    static let focusRing = Color.accentColor
    static let error = Color(.systemRed)
}

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
        case mild = "轻度"
        case moderate = "中度"
        case severe = "重度"
        case critical = "危重"
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
            SymptomTokens.pageBG(scheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    symptomBadge("🤒 症状")

                    symptomCard {
                        sectionTitle(icon: "calendar", text: "基本信息")

                        gridTwoSymptom {
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("日期", required: true)
                                DatePicker("", selection: $form.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .modifier(SymptomFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("时间", required: true)
                                DatePicker("", selection: $form.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .modifier(SymptomFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                        }

                        dividerSymptom()

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("标题", required: true)
                            let titleError = form.title.trimmed().isEmpty
                            TextField("请输入记录标题", text: $form.title)
                                .textInputAutocapitalization(.never)
                                .focused($focus, equals: .title)
                                .submitLabel(.next)
                                .modifier(SymptomFieldChrome(isFocused: focus == .title, isError: titleError, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("详细描述", required: true)
                            let detailError = form.detail.trimmed().isEmpty
                            symptomTextArea("请输入详细描述...", text: $form.detail, isFocused: focus == .detail, isError: detailError)
                                .focused($focus, equals: .detail)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("症状严重程度")
                            Picker(selection: $form.severity) {
                                Text("选择严重程度").tag(Optional<Severity>.none)
                                ForEach(Severity.allCases) { s in
                                    Text("\(s.icon) \(s.rawValue)").tag(Optional(s))
                                }
                            } label: {
                                HStack {
                                    Text(form.severity?.rawValue ?? "选择严重程度")
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.down").opacity(0.5)
                                }
                            }
                            .pickerStyle(.menu)
                            .modifier(SymptomFieldChrome(isFocused: false, isError: false, scheme: scheme))
                        }
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // 固定底部操作区
            VStack { Spacer()
                HStack {
                    Button(action: cancelNow) { Text("取消") }
                        .buttonStyle(BorderButtonStyleSymptom())
                    Button(action: saveNow) {
                        Label("保存记录", systemImage: "check")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(PrimaryButtonStyleSymptom())
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.6)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: SymptomTokens.subtleShadow(scheme), radius: 10, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
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

    func combinedDateTime() -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year,.month,.day], from: form.date)
        let t = cal.dateComponents([.hour,.minute,.second], from: form.time)
        var c = DateComponents(); c.year=d.year; c.month=d.month; c.day=d.day; c.hour=t.hour; c.minute=t.minute; c.second=t.second ?? 0
        return cal.date(from: c) ?? form.date
    }
}

// MARK: - View Helpers（独特命名）
private extension CDSymptomFormView {
    @ViewBuilder func symptomBadge(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(Color.orange.opacity(0.12))
            .foregroundStyle(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder func symptomCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .padding(16)
            .background(SymptomTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(SymptomTokens.border(scheme), lineWidth: 1))
            .shadow(color: SymptomTokens.subtleShadow(scheme), radius: 12, y: 4)
    }

    @ViewBuilder func sectionTitle(icon: String, text: String) -> some View {
        HStack(spacing: 8) { Image(systemName: icon); Text(text).font(.headline) }
    }

    @ViewBuilder func dividerSymptom() -> some View {
        Rectangle().fill(SymptomTokens.border(scheme)).frame(height: 1).padding(.vertical, 4)
    }

    @ViewBuilder func gridTwoSymptom<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12, content: content)
        #else
        HStack(spacing: 12, content: content)
        #endif
    }

    @ViewBuilder func formLabel(_ text: String, required: Bool = false) -> some View {
        HStack(spacing: 4) { Text(text).font(.subheadline.weight(.medium)); if required { Text("*").foregroundStyle(.red) } }
            .accessibilityLabel(Text(required ? "\(text) 必填" : text))
    }

    func symptomTextArea(_ placeholder: String, text: Binding<String>, isFocused: Bool, isError: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .frame(minHeight: 100)
                .padding(.horizontal, 10).padding(.vertical, 10)
                .background(SymptomTokens.fieldBG(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isError ? SymptomTokens.error : (isFocused ? SymptomTokens.focusRing : SymptomTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
                )
                .shadow(color: SymptomTokens.subtleShadow(scheme), radius: isFocused ? 8 : 4, y: 2)
            if text.wrappedValue.isEmpty {
                Text(placeholder).foregroundStyle(.secondary).padding(.top, 14).padding(.leading, 16).allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Field Chrome（独特命名）
private struct SymptomFieldChrome: ViewModifier {
    let isFocused: Bool
    let isError: Bool
    let scheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(SymptomTokens.fieldBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? SymptomTokens.error : (isFocused ? SymptomTokens.focusRing : SymptomTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
            )
            .shadow(color: SymptomTokens.subtleShadow(scheme), radius: isFocused ? 8 : 4, y: 2)
    }
}

// MARK: - Buttons（独特命名但风格一致）
private struct PrimaryButtonStyleSymptom: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.85) : Color.accentColor)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct BorderButtonStyleSymptom: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(SymptomTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(SymptomTokens.border(scheme), lineWidth: 1))
    }
}
//
//// MARK: - Utils
//private extension String { func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) } }

// MARK: - Preview
struct CDSymptomFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDSymptomFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDSymptomFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}

