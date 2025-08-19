//
//  Screen.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//
import SwiftUI

public enum Screen {
    /// 物理屏幕像素点（不随分屏变化）
    public static var nativeBounds: CGRect {
        UIScreen.main.nativeBounds
    }
    /// 逻辑点（可能与实际容器不符；布局请用 GeometryReader）
    public static var bounds: CGRect {
        UIScreen.main.bounds
    }
    /// 缩放因子
    public static var scale: CGFloat {
        UIScreen.main.scale
    }
}
