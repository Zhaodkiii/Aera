//
//  FormTextArea.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI

// HealthFormsKit • Fields
// 通用多行输入框：带标签、必填校验、焦点状态
public struct FormTextArea: View {
    private let label: String
    private let placeholder: String
    private let required: Bool
    @Binding private var text: String
    @FocusState private var isFocused: Bool
    
    private let scheme: ColorScheme

    public init(
        _ label: String,
        placeholder: String = "",
        required: Bool = false,
        text: Binding<String>,
        scheme: ColorScheme
    ) {
        self.label = label
        self.placeholder = placeholder
        self.required = required
        self._text = text
        self.scheme = scheme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormLabel(label, required: required)
            let isError = text.trimmed().isEmpty && required
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
//                    .padding(.horizontal, 10).padding(.vertical, 10)
                    .focused($isFocused)
                    .modifier(FormFieldChromea(isFocused: isFocused, isError: isError, scheme: scheme))
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                        .padding(.top, 14).padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}


// MARK: - 公共修饰器（替代 MedFieldChrome / SymptomFieldChrome 等）
public struct FormFieldChromea: ViewModifier {
    let isFocused: Bool
    let isError: Bool
    let scheme: ColorScheme

    public func body(content: Content) -> some View {
        content
            .padding(10)
            .background(DesignTokens.fieldBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isError ? DesignTokens.error : (isFocused ? DesignTokens.focusRing : DesignTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
            )
            .shadow(color: DesignTokens.subtleShadow(scheme), radius: isFocused ? 8 : 4, y: 2)
    }
}
