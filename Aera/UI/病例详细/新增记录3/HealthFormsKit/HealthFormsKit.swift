//
//  HealthFormsKit.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI

// MARK: - HealthFormsKit
// 抽出公共样式与组件，减少重复代码；所有表单页（报告/就医/症状/用药/手术/随访）统一引用。
// 组成：DesignTokens、FormCard、FormBadge、FormLabel、FormDivider、GridTwo、FormFieldChrome、TextAreaField、PickerField、工具扩展

// MARK: - Design Tokens（浅/深色自适应，三层对比）

// MARK: - Design Tokens（解决“输入框与背景同色、识别度低”的根因）
enum DesignTokens {
    // 页面整体背景（比卡片更浅/更亮，制造层级）
    static func pageBG(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)
    }
    // 卡片背景（与页面背景区分）
    static func cardBG(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    // 输入框背景（与卡片背景对比更强：浅灰/深灰 + 细微渐变）
    static func fieldBG(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(colors: [Color(white: 0.14), Color(white: 0.10)], startPoint: .top, endPoint: .bottom)
        } else {
            return LinearGradient(colors: [Color(white: 0.98), Color(white: 0.96)], startPoint: .top, endPoint: .bottom)
        }
    }
    // 边框与投影
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    static func subtleShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.08)
    }

    // 聚焦与错误态
    static let focusRing = Color.accentColor
    
    static let error = Color(.systemRed)
}

// MARK: - Common Containers
public struct FormCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    public var body: some View {
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
}

public struct FormBadge: View {
    let text: String
    let color: Color
    public init(_ text: String, color: Color) { self.text = text; self.color = color }
    public var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

public struct FormLabel: View {
    let text: String
    let required: Bool
    public init(_ text: String, required: Bool = false) { self.text = text; self.required = required }
    public var body: some View {
        HStack(spacing: 4) {
            Text(text).font(.subheadline.weight(.medium))
            if required { Text("*").foregroundStyle(.red) }
        }
        .accessibilityLabel(Text(required ? "\(text) 必填" : text))
    }
}

public struct FormDivider: View {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public var body: some View { Rectangle().fill(DesignTokens.border(scheme)).frame(height: 1).padding(.vertical, 4) }
}

public struct GridTwo<Content: View>: View {
    let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    public var body: some View {
        #if os(iOS)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12, content: content)
        #else
        HStack(spacing: 12, content: content)
        #endif
    }
}

// MARK: - Field Chrome（统一输入外观）
public struct FormFieldChrome: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    let isFocused: Bool
    let isError: Bool
    public init(isFocused: Bool, isError: Bool) { self.isFocused = isFocused; self.isError = isError }
    public func body(content: Content) -> some View {
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

public extension View {
    func formFieldChrome(isFocused: Bool = false, isError: Bool = false) -> some View {
        modifier(FormFieldChrome(isFocused: isFocused, isError: isError))
    }
}

// MARK: - TextArea（统一多行输入外观，含占位符）
public struct TextAreaField: View {
    @Environment(\.colorScheme) private var scheme
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    let isError: Bool
    public init(_ placeholder: String, text: Binding<String>, isFocused: Bool = false, isError: Bool = false) {
        self.placeholder = placeholder; self._text = text; self.isFocused = isFocused; self.isError = isError
    }
    public var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .padding(.horizontal, 10).padding(.vertical, 10)
                .background(DesignTokens.fieldBG(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isError ? DesignTokens.error : (isFocused ? DesignTokens.focusRing : DesignTokens.border(scheme)), lineWidth: isFocused || isError ? 1.5 : 1)
                )
                .shadow(color: DesignTokens.subtleShadow(scheme), radius: isFocused ? 8 : 4, y: 2)
            if text.isEmpty {
                Text(placeholder).foregroundStyle(.secondary).padding(.top, 14).padding(.leading, 16).allowsHitTesting(false)
            }
        }
    }
}

// MARK: - PickerField（统一 Picker 外观）
public struct PickerField<SelectionValue: Hashable, ContentLabel: View, ContentOptions: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selection: SelectionValue?
    let label: () -> ContentLabel
    let options: () -> ContentOptions
    public init(selection: Binding<SelectionValue?>, @ViewBuilder label: @escaping () -> ContentLabel, @ViewBuilder options: @escaping () -> ContentOptions) {
        self._selection = selection; self.label = label; self.options = options
    }
    public var body: some View {
        Picker(selection: $selection) { options() } label: { label() }
            .pickerStyle(.menu)
            .modifier(FormFieldChrome(isFocused: false, isError: false))
    }
}

// MARK: - Utilities
extension String { func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) } }
// MARK: - Binding Helpers
extension Binding where Value == String? {
    func orEmpty() -> Binding<String> {
        .init(get: { self.wrappedValue ?? "" }, set: { self.wrappedValue = $0.isEmpty ? nil : $0 })
    }
}
public enum FormActions {
    public static func combined(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year,.month,.day], from: date)
        let t = cal.dateComponents([.hour,.minute,.second], from: time)
        var c = DateComponents(); c.year=d.year; c.month=d.month; c.day=d.day; c.hour=t.hour; c.minute=t.minute; c.second=t.second ?? 0
        return cal.date(from: c) ?? date
    }
}

// MARK: - Buttons（保持既有风格，供所有页面共用）
struct PrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.85) : Color.accentColor)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct BorderButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(DesignTokens.cardBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(DesignTokens.border(scheme), lineWidth: 1))
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


// MARK: - View 扩展，方便调用
public extension View {
    func inputFieldChrome(isFocused: Bool, isError: Bool, scheme: ColorScheme) -> some View {
        self.modifier(InputFieldChrome(isFocused: isFocused, isError: isError, scheme: scheme))
    }
}


import SwiftUI

// HealthFormsKit • Fields
// 通用选择器（下拉菜单形式，适配任意 String RawRepresentable 的枚举）
public struct FormPicker<T: CaseIterable & RawRepresentable & Hashable>: View where T.RawValue == String {
    private let label: String
    private let required: Bool
    private let placeholder: String
    @Binding private var selection: T?
    private let scheme: ColorScheme

    public init(
        _ label: String,
        required: Bool = false,
        placeholder: String? = nil,
        selection: Binding<T?>,
        scheme: ColorScheme
    ) {
        self.label = label
        self.required = required
        self.placeholder = placeholder ?? "请选择\(label)"
        self._selection = selection
        self.scheme = scheme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormLabel(label, required: required)

            let isError = required && selection == nil

            Picker(selection: $selection) {
                Text(placeholder).tag(Optional<T>.none)
                // 关键修正：把 allCases 包成 Array 并用 id: \.self
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(Optional(option))
                }
            } label: {
                HStack {
                    Text(selection?.rawValue ?? placeholder)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down").opacity(0.5)
                }
            }
            .pickerStyle(.menu)
            .formFieldChrome(isFocused: false, isError: isError)
//            .modifier(InputFieldChrome(isFocused: false, isError: false, scheme: scheme))

        }
    }
}
