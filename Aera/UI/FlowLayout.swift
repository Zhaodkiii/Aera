//
//  FlowLayout.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//
import SwiftUI


import SwiftUI

/// 高性能换行布局（iOS 16+）
/// - 支持行间距/列间距、水平对齐（leading/center/trailing）
/// - 处理“某个子视图宽于容器”的边界：该子视图独占一行，宽度按容器宽度放置
/// - 可选 `maxRows`：用于卡片里限制展示的最大行数（其余内容可用“+N”补充）
struct FlowLayout: Layout {
    struct Cache {
        var sizes: [CGSize] = []
        var rows: [[Int]] = []
        var rowHeights: [CGFloat] = []
        var containerWidth: CGFloat = 0
    }
    
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading
    var maxRows: Int? = nil
    
    init(spacing: CGFloat = 8, runSpacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, maxRows: Int? = nil) {
        self.spacing = spacing
        self.runSpacing = runSpacing
        self.alignment = alignment
        self.maxRows = maxRows
    }
    
    // MARK: Cache
    func makeCache(subviews: Subviews) -> Cache { Cache() }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {}
    
    // MARK: Size
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        let cw = containerWidth.isFinite ? containerWidth : UIScreen.main.bounds.width // 安全兜底
        
        // 1) 预测量所有子视图尺寸（不限制宽高）
        cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        // 2) 按行分组
        (cache.rows, cache.rowHeights) = computeRows(sizes: cache.sizes, containerWidth: cw)
        cache.containerWidth = cw
        
        // 3) 限制最大行数
        let rowsCount = maxRows.map { min($0, cache.rows.count) } ?? cache.rows.count
        let usedHeights = cache.rowHeights.prefix(rowsCount)
        
        let totalHeight = usedHeights.reduce(0, +) + (CGFloat(max(rowsCount - 1, 0)) * runSpacing)
        let maxRowWidth = rowMaxWidths(rows: Array(cache.rows.prefix(rowsCount)),
                                       sizes: cache.sizes,
                                       containerWidth: cw)
        
        return CGSize(width: maxRowWidth, height: totalHeight)
    }
    
    // MARK: Placement
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let cw = bounds.width
        let (rows, rowHeights) = (cache.rows, cache.rowHeights)
        let limit = maxRows.map { min($0, rows.count) } ?? rows.count
        
        var y: CGFloat = bounds.minY
        for r in 0..<limit {
            let row = rows[r]
            let rowH = rowHeights[r]
            let rowW = rowWidth(row, sizes: cache.sizes, containerWidth: cw)
            var x: CGFloat = bounds.minX + startX(for: rowW, in: cw, alignment: alignment)
            
            for idx in row {
                var size = cache.sizes[idx]
                // 若单个项比容器宽，按容器宽铺开
                if size.width > cw { size.width = cw }
                
                let point = CGPoint(x: x, y: y + (rowH - size.height)/2)
                subviews[idx].place(at: point,
                                    proposal: ProposedViewSize(width: size.width, height: size.height))
                x += size.width + spacing
            }
            y += rowH + runSpacing
        }
    }
    
    // MARK: Row computation
    private func computeRows(sizes: [CGSize], containerWidth cw: CGFloat) -> (rows: [[Int]], heights: [CGFloat]) {
        var rows: [[Int]] = []
        var heights: [CGFloat] = []
        
        var currentRow: [Int] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        
        for (i, size0) in sizes.enumerated() {
            var size = size0
            // 超宽项独占一行（宽度按容器宽）
            if size.width > cw { size.width = cw }
            
            let nextWidth = currentRow.isEmpty ? size.width : (currentWidth + spacing + size.width)
            if nextWidth <= cw || currentRow.isEmpty {
                // 放在当前行
                currentRow.append(i)
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            } else {
                // 换行
                rows.append(currentRow)
                heights.append(currentHeight)
                currentRow = [i]
                currentWidth = size.width
                currentHeight = size.height
            }
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
            heights.append(currentHeight)
        }
        return (rows, heights)
    }
    
    // 每行起始 X（用于居中/右对齐）
    private func startX(for rowWidth: CGFloat, in cw: CGFloat, alignment: HorizontalAlignment) -> CGFloat {
        switch alignment {
        case .center: return (cw - rowWidth)/2
        case .trailing: return max(cw - rowWidth, 0)
        default: return 0
        }
    }
    
    private func rowWidth(_ row: [Int], sizes: [CGSize], containerWidth cw: CGFloat) -> CGFloat {
        guard !row.isEmpty else { return 0 }
        var w: CGFloat = 0
        for (j, idx) in row.enumerated() {
            let itemW = min(sizes[idx].width, cw)
            w += itemW
            if j < row.count - 1 { w += spacing }
        }
        return w
    }
    private func rowMaxWidths(rows: [[Int]], sizes: [CGSize], containerWidth cw: CGFloat) -> CGFloat {
        rows.map { rowWidth($0, sizes: sizes, containerWidth: cw) }.max() ?? 0
    }
}

//struct FlowLayout<Content: View>: View {
//    let spacing: CGFloat
//    let runSpacing: CGFloat
//    @ViewBuilder let content: Content
//    
//    init(spacing: CGFloat = 8, runSpacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
//        self.spacing = spacing
//        self.runSpacing = runSpacing
//        self.content = content()
//    }
//    
//    var body: some View {
//        GeometryReader { proxy in
//            self.generateContent(in: proxy.size)
//        }
//        .frame(minHeight: 0)
//    }
//    
//    private func generateContent(in size: CGSize) -> some View {
//        var width: CGFloat = 0
//        var height: CGFloat = 0
//        
//        return ZStack(alignment: .topLeading) {
//            content
//                .padding(.trailing, spacing)
//                .alignmentGuide(.leading) { d in
//                    if abs(width - d.width) > size.width {
//                        width = 0
//                        height -= (d.height + runSpacing)
//                    }
//                    let result = width
//                    width -= d.width + spacing
//                    return result
//                }
//                .alignmentGuide(.top) { d in
//                    let result = height
//                    return result
//                }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//}
