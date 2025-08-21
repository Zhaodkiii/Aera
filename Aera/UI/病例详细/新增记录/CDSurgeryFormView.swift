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
                    surgeryBadge("🔪 手术")

                    card {
                        sectionHeader(icon: "calendar", title: "基本信息")

                        gridTwo {
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("日期", required: true)
                                DatePicker("", selection: $form.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .modifier(InputFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                formLabel("时间", required: true)
                                DatePicker("", selection: $form.time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .modifier(InputFieldChrome(isFocused: false, isError: false, scheme: scheme))
                            }
                        }

                        divider()

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("标题", required: true)
                            let titleError = form.title.trimmed().isEmpty
                            TextField("请输入记录标题", text: $form.title)
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .focused($focus, equals: .title)
                                .modifier(InputFieldChrome(isFocused: focus == .title, isError: titleError, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("详细描述", required: true)
                            let detailError = form.detail.trimmed().isEmpty
                            textArea("请输入详细描述...", text: $form.detail, isFocused: focus == .detail, isError: detailError)
                                .focused($focus, equals: .detail)
                        }

                        divider()

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("手术名称")
                            TextField("手术名称", text: $form.surgeryName.orEmpty())
                                .textInputAutocapitalization(.never)
                                .focused($focus, equals: .surgeryName)
                                .modifier(InputFieldChrome(isFocused: focus == .surgeryName, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("手术医生")
                            TextField("主刀医生姓名", text: $form.surgeon.orEmpty())
                                .textInputAutocapitalization(.words)
                                .focused($focus, equals: .surgeon)
                                .modifier(InputFieldChrome(isFocused: focus == .surgeon, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("麻醉方式")
                            Picker(selection: $form.anesthesia) {
                                Text("选择麻醉方式").tag(Optional<Anesthesia>.none)
                                ForEach(Anesthesia.allCases) { a in
                                    Text(a.rawValue).tag(Optional(a))
                                }
                            } label: {
                                HStack { Text(form.anesthesia?.rawValue ?? "选择麻醉方式"); Spacer(); Image(systemName: "chevron.down").opacity(0.5) }
                            }
                            .pickerStyle(.menu)
                            .modifier(InputFieldChrome(isFocused: false, isError: false, scheme: scheme))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            formLabel("术后情况")
                            textArea("手术效果、并发症或注意事项...", text: $form.postOpNotes.orEmpty(), isFocused: focus == .postOpNotes, isError: false)
                                .focused($focus, equals: .postOpNotes)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            // 固定底部操作条
            VStack {
                Spacer()
                HStack {
                    Button(action: cancelNow) { Text("取消") }
                        .buttonStyle(BorderButtonStyle())
                    Button(action: saveNow) { Label("保存记录", systemImage: "check") }
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

// MARK: - UI Helpers（手术页专属）
private extension CDSurgeryFormView {
    @ViewBuilder func surgeryBadge(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(Color.red.opacity(0.15))
            .foregroundStyle(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

//// MARK: - Binding Helper
//private extension String { func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) } }

// MARK: - Preview
struct CDSurgeryFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView { CDSurgeryFormView { _ in } }.preferredColorScheme(.light)
            NavigationView { CDSurgeryFormView { _ in } }.preferredColorScheme(.dark)
        }
    }
}


// MARK: - View Helpers & Styles
private extension CDSurgeryFormView {
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
