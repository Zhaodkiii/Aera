//
//  SymptomFieldChrome.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

import SwiftUI


// MARK: - Field Chrome（公共 ViewModifier）
public struct SymptomFieldChrome: ViewModifier {
    let isFocused: Bool
    let isError: Bool
    let scheme: ColorScheme

    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(DesignTokens.fieldBG(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isError
                        ? DesignTokens.error
                        : (isFocused ? DesignTokens.focusRing : DesignTokens.border(scheme)),
                        lineWidth: isFocused || isError ? 1.5 : 1
                    )
            )
            .shadow(color: DesignTokens.subtleShadow(scheme), radius: isFocused ? 8 : 4, y: 2)
    }
}

// MARK: - View 扩展，方便调用
public extension View {
    func symptomFieldChrome(isFocused: Bool, isError: Bool, scheme: ColorScheme) -> some View {
        self.modifier(SymptomFieldChrome(isFocused: isFocused, isError: isError, scheme: scheme))
    }
}
