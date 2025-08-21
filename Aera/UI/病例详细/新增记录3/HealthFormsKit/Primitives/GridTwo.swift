//
//  GridTwo.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/21.
//

import SwiftUI

// HealthFormsKit • Layouts
// GridTwo：两列自适应网格（iOS 用 LazyVGrid，macOS/iPad 外也能优雅降级）
public struct GridTwo<Content: View>: View {
    private let content: () -> Content
    public init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    public var body: some View {
        #if os(iOS)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12, content: content)
        #else
        HStack(spacing: 12, content: content)
        #endif
    }
}

// 如需更多列，可扩展为泛化版本（可选）：
public struct GridColumns<Content: View>: View {
    private let columns: Int
    private let spacing: CGFloat
    private let content: () -> Content
    public init(_ columns: Int, spacing: CGFloat = 12, @ViewBuilder content: @escaping () -> Content) {
        self.columns = max(1, columns)
        self.spacing = spacing
        self.content = content
    }
    public var body: some View {
        #if os(iOS)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: spacing, content: content)
        #else
        HStack(spacing: spacing, content: content)
        #endif
    }
}
