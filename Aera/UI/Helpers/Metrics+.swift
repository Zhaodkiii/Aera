//
//  Metrics+.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import SwiftUI

// 1) 尺寸数据模型
public struct Metrics: Equatable {
    public var containerSize: CGSize         // 当前 View 可用区域（更可靠）
    public var safeAreaInsets: EdgeInsets
    public var horizontalSizeClass: UserInterfaceSizeClass?
    public var verticalSizeClass: UserInterfaceSizeClass?
    public var idiom: UIUserInterfaceIdiom   // iPhone / iPad / MacCatalyst

    // 便捷属性
    public var width: CGFloat { containerSize.width }
    public var height: CGFloat { containerSize.height }
    public var isCompact: Bool { horizontalSizeClass == .compact }
    public var isRegular: Bool { horizontalSizeClass == .regular }

    // 建议的「最小卡片宽度」：紧凑/常规屏给不同阈值
    public func suggestedMinCardWidth(compact: CGFloat = 300, regular: CGFloat = 360) -> CGFloat {
        isCompact ? compact : regular
    }

    // 根据目标最小宽度与列间距，计算自适应列数（≥1）
    public func adaptiveColumnCount(minItemWidth: CGFloat, spacing: CGFloat = 16) -> Int {
        guard width > 0 else { return 1 }
        let available = width - spacing // 两侧留点余量（粗略）
        let count = Int((available + spacing) / (minItemWidth + spacing))
        return max(1, count)
    }
}

// 2) EnvironmentKey
private struct MetricsKey: EnvironmentKey {
    static let defaultValue = Metrics(
        containerSize: .zero,
        safeAreaInsets: .init(),
        horizontalSizeClass: nil,
        verticalSizeClass: nil,
        idiom: UIDevice.current.userInterfaceIdiom
    )
}

public extension EnvironmentValues {
    var metrics: Metrics {
        get { self[MetricsKey.self] }
        set { self[MetricsKey.self] = newValue }
    }
}

// 3) View 修饰器：把尺寸注入到 Environment
public struct MetricsInjector: ViewModifier {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass)   private var vSize

    public func body(content: Content) -> some View {
        GeometryReader { proxy in
            // 用 GeometryReader 读取容器可用区域 + safe area
            let size = proxy.size
            let insets = proxy.safeAreaInsets  // iOS 16+，若需要兼容 15，可用 UIApplication 兜底

            content
                .environment(\.metrics, Metrics(
                    containerSize: size,
                    safeAreaInsets: insets,
                    horizontalSizeClass: hSize,
                    verticalSizeClass: vSize,
                    idiom: UIDevice.current.userInterfaceIdiom
                ))
        }
    }
}


public extension View {
    /// 在页面根节点或需要的子树上调用一次即可
    func injectMetrics() -> some View {
        self.modifier(MetricsInjector())
    }
}
