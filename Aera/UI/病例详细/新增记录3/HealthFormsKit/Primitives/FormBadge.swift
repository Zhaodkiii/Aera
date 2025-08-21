//
//  FormBadge.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/21.
//
import SwiftUI

/// HealthFormsKit • Primitives
/// FormBadge：通用徽章组件（替代各页面的 private `badge`/`followBadge` 等）
public struct FormBadge: View {
    private let text: String
    private let color: Color

    /// - Parameters:
    ///   - text: 徽章文字（可含表情/图标，如 "📞 随访"）
    ///   - color: 主题色（用于前景色与 12% 不透明背景）
    public init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}
