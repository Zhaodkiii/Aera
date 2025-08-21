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
                    badge("📄 检查报告")

                    card {
                        sectionHeader(icon: "calendar", title: "基本信息")
                        gridTwo {
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("日期", required: true)
                                DatePicker("", selection: $form.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .modifier(InputFieldChrome(isFocused: focusedField == .title, isError: false, scheme: scheme))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("时间", required: true)
                                DatePicker("", selection: $form.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .modifier(InputFieldChrome(isFocused: focusedField == .title, isError: false, scheme: scheme))
                            }
                        }

                        divider()

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("标题", required: true)
                            let titleError = form.title.trimmed().isEmpty
                            TextField("请输入记录标题", text: $form.title)
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .title)
                                .modifier(InputFieldChrome(isFocused: focusedField == .title, isError: titleError, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("详细描述", required: true)
                            let detailError = form.detail.trimmed().isEmpty
                            textArea("请输入详细描述...", text: $form.detail,
                                     isFocused: focusedField == .detail,
                                     isError: detailError)
                                .focused($focusedField, equals: .detail)
                        }

                        divider()

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("报告名称")
                            TextField("如：血常规检查报告", text: $form.reportName.orEmpty())
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .reportName)
                                .modifier(InputFieldChrome(isFocused: focusedField == .reportName, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("检查类型")
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

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("检查结论")
                            textArea("检查结论...", text: $form.conclusion.orEmpty(), isFocused: focusedField == .conclusion, isError: false)
                                .focused($focusedField, equals: .conclusion)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("医生建议")
                            textArea("医生建议或注意事项...", text: $form.doctorAdvice.orEmpty(), isFocused: focusedField == .doctorAdvice, isError: false)
                                .focused($focusedField, equals: .doctorAdvice)
                        }
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // 固定底部操作条（提升可达性）
            VStack { Spacer()
                HStack {
                    Button(action: cancelNow) { Text("取消") }
                        .buttonStyle(BorderButtonStyle())
                    Button(action: saveNow) {
                        Label("保存记录", systemImage: "check")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.6)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: DesignTokens.subtleShadow(scheme), radius: 10, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
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

    func combinedDateTime() -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year,.month,.day], from: form.date)
        let t = cal.dateComponents([.hour,.minute,.second], from: form.time)
        var c = DateComponents(); c.year=d.year; c.month=d.month; c.day=d.day; c.hour=t.hour; c.minute=t.minute; c.second=t.second ?? 0
        return cal.date(from: c) ?? form.date
    }
}



// MARK: - View Helpers & Styles
private extension CDReportFormView {
    @ViewBuilder func badge(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(Color.accentColor.opacity(0.12))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content)
            .padding(16)
            .background(DesignTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(DesignTokens.border(scheme), lineWidth: 1)
            )
            .shadow(color: DesignTokens.subtleShadow(scheme), radius: 12, y: 4)
    }

    @ViewBuilder func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) { Image(systemName: icon); Text(title).font(.headline) }
    }

    @ViewBuilder func divider() -> some View {
        Rectangle().fill(DesignTokens.border(scheme)).frame(height: 1).padding(.vertical, 4)
    }

    @ViewBuilder func gridTwo<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    func textArea(_ placeholder: String, text: Binding<String>, isFocused: Bool, isError: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .frame(minHeight: 100)
                .padding(.horizontal, 10).padding(.vertical, 10)
                .background(DesignTokens.fieldBG(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isError ? DesignTokens.error : (isFocused ? DesignTokens.focusRing : DesignTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
                )
                .shadow(color: DesignTokens.subtleShadow(scheme), radius: isFocused ? 8 : 4, y: 2)
            if text.wrappedValue.isEmpty {
                Text(placeholder).foregroundStyle(.secondary).padding(.top, 14).padding(.leading, 16).allowsHitTesting(false)
            }
        }
    }
}

// 输入类控件统一外观
struct InputFieldChrome: ViewModifier {
    let isFocused: Bool
    let isError: Bool
    let scheme: ColorScheme

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(DesignTokens.fieldBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? DesignTokens.error : (isFocused ? DesignTokens.focusRing : DesignTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
            )
            .shadow(color: DesignTokens.subtleShadow(scheme), radius: isFocused ? 8 : 4, y: 2)
    }
}


//// MARK: - Utilities
//private extension String { func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) } }

// MARK: - Preview
struct CDReportFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDReportFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDReportFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}

