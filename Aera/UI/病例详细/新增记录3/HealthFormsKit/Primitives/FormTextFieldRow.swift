//
//  FormTextFieldRow.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/21.
//

import SwiftUI
import SwiftUI

// HealthFormsKit • Fields
// 通用「标签 + 文本输入」行，带必填校验、聚焦高亮、占位符与提交行为。
public struct FormTextFieldRow: View {
    // MARK: Inputs
    private let label: String
    private let required: Bool
    private let placeholder: String
    @Binding private var text: String

    // 交互配置
    private let submitLabel: SubmitLabel
    private let textInputAutocapitalization: TextInputAutocapitalization?
    private let keyboardType: UIKeyboardType?
    private let validator: ((String) -> Bool)?
    private let onSubmit: (() -> Void)?

    // 可选：由父视图传入的焦点绑定（需要外部统一管理焦点时使用）
    private let externalFocus: FocusState<Bool>.Binding?

    // 内部焦点（当没有外部焦点时使用）
    @FocusState private var internalFocused: Bool

    // MARK: Init
    /// - Parameters:
    ///   - label: 左侧标题
    ///   - required: 是否必填（为空时显示错误态）
    ///   - placeholder: 占位符
    ///   - text: 文本绑定
    ///   - submitLabel: 键盘提交按钮样式（默认 .next）
    ///   - textInputAutocapitalization: 大小写策略（默认 .never）
    ///   - keyboardType: 键盘类型（默认 nil 使用系统默认）
    ///   - validator: 自定义校验（返回 true 表示通过）
    ///   - onSubmit: 提交回调（回车/提交时触发）
    ///   - focus: 可选外部焦点绑定（需要时传入）
    public init(
        label: String,
        required: Bool = false,
        placeholder: String = "",
        text: Binding<String>,
        submitLabel: SubmitLabel = .next,
        textInputAutocapitalization: TextInputAutocapitalization? = .never,
        keyboardType: UIKeyboardType? = nil,
        validator: ((String) -> Bool)? = nil,
        onSubmit: (() -> Void)? = nil,
        focus: FocusState<Bool>.Binding? = nil
    ) {
        self.label = label
        self.required = required
        self.placeholder = placeholder
        self._text = text
        self.submitLabel = submitLabel
        self.textInputAutocapitalization = textInputAutocapitalization
        self.keyboardType = keyboardType
        self.validator = validator
        self.onSubmit = onSubmit
        self.externalFocus = focus
    }

    // MARK: Body
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormLabel(label, required: required)

            // 计算错误态
            let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let valid = validator?(text) ?? true
            let isError = (required && isEmpty) || !valid

            // TextField
            Group {
                if let focus = externalFocus {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(textInputAutocapitalization)
                        .keyboardType(keyboardType ?? .default)
                        .submitLabel(submitLabel)
                        .focused(focus)
                        .formFieldChrome(isFocused: focus.wrappedValue, isError: isError)
                        .onSubmit { onSubmit?() }
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(textInputAutocapitalization)
                        .keyboardType(keyboardType ?? .default)
                        .submitLabel(submitLabel)
                        .focused($internalFocused)
                        .formFieldChrome(isFocused: internalFocused, isError: isError)
                        .onSubmit { onSubmit?() }
                }
            }
        }
    }
}
