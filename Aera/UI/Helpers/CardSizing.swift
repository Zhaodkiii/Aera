//
//  CardSizing.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//


import SwiftUI

/// 统一控制卡片的尺寸表现
struct CardSizing: Equatable {
    var contentPadding: CGFloat = 16
    var cornerRadius: CGFloat  = 16
    var minHeight: CGFloat     = 140          // 卡片最小高度（内容不足时维持视觉重量）
    var maxReadingWidth: CGFloat = 900        // 大屏时限制最大阅读宽度（放在容器上用）
    var aspectRatio: CGFloat?   = nil         // 需要统一高度时可选 16/9、4/3 等。nil 表示用 minHeight

    /// 预设：手机/紧凑屏
    static let compact = CardSizing(contentPadding: 14, cornerRadius: 14, minHeight: 132, maxReadingWidth: 820, aspectRatio: nil)
    /// 预设：iPad/横屏
    static let regular = CardSizing(contentPadding: 16, cornerRadius: 16, minHeight: 148, maxReadingWidth: 900, aspectRatio: nil)
    /// 预设：瀑布流统一比例（示例 16:9）
    static let uniform16x9 = CardSizing(contentPadding: 14, cornerRadius: 14, minHeight: 0, maxReadingWidth: 900, aspectRatio: 16.0/9.0)
}
