//
//  SymptomCard.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

import SwiftUI


public struct SymptomCard<Content: View>: View {
    private let scheme: ColorScheme
    private let content: Content
    
    public init(scheme: ColorScheme, @ViewBuilder content: () -> Content) {
        self.scheme = scheme
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
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
