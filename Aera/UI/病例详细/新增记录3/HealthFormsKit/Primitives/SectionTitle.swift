//
//  SectionTitle.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//


import SwiftUI

// HealthFormsKit • Sections
// 公共分组标题：带系统图标
struct SectionTitle: View {
    private let icon: String
    private let text: String

    init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.headline)
        }
    }
}
