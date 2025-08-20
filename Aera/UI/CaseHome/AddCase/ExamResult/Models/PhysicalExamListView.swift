//
//  PhysicalExamListView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/20.
//

import SwiftUI

struct PhysicalExamListView: View {
    @State private var items: [ExamItemaaa] = ExamDataLoader.demoa
    @State private var query: String = ""
    @State private var tab: FilterTab = .all

    // 搜索 + 状态筛选
    private var filtered: [ExamItemaaa] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base: [ExamItemaaa]
        switch tab {
        case .all: base = items
        case .normal: base = items.filter { $0.status == .正常 }
        case .abnormal: base = items.filter { $0.status == .异常 }
        }
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.itemName.localizedCaseInsensitiveContains(q)
            || $0.category.localizedCaseInsensitiveContains(q)
            || $0.conclusion.localizedCaseInsensitiveContains(q)
            || $0.result.localizedCaseInsensitiveContains(q)
        }
    }

    // 分组（按 category）
    private var groups: [(category: String, rows: [ExamItemaaa])] {
        let dict = Dictionary(grouping: filtered, by: { $0.category })
        return dict.keys.sorted().map { key in
            (key, dict[key]!.sorted { $0.id < $1.id })
        }
    }

    // 统计
    private var totalCount: Int { items.count }
    private var normalCount: Int { items.filter{ $0.status == .正常 }.count }
    private var abnormalCount: Int { items.filter{ $0.status == .异常 }.count }
    @ViewBuilder
    func AbnormalBadge(_ count: Int) -> some View {
        if count > 0 {
            Badgeaq(text: "\(count)项异常", style: .destructive)
        }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 搜索框
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索检查项目...", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5)
                )
                .padding(.top, 8)

                // Tabs
                HStack(spacing: 6) {
                    TabChip(title: "全部(\(totalCount))", isOn: tab == .all) { tab = .all }
                    TabChip(title: "正常(\(normalCount))", isOn: tab == .normal) { tab = .normal }
                    TabChip(title: "异常(\(abnormalCount))", isOn: tab == .abnormal) { tab = .abnormal }
                }

                // 分类列表
                VStack(spacing: 12) {
                    ForEach(groups, id: \.category) { group in
                        let abnormalInGroup = group.rows.filter { $0.status == .异常 }.count
                        CollapsibleCardaa {
                            // 头部
                            HStack(spacing: 10) {
                                GroupIcon(name: group.category)
                                Text(group.category)
                                    .font(.headline)

                                // 使用
                                Badgeaq(text:"\(group.rows.count)项")
                                if abnormalInGroup > 0 {
                                    Badgeaq(text: "\(abnormalInGroup)项异常", style: .destructive)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        } content: {
                            VStack(spacing: 0) {
                                ForEach(group.rows) { row in
                                    ExamRowCard(row: row)
                                        .padding(.horizontal, 16)

                                    if row.id != group.rows.last?.id {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                                .padding(.vertical, 2)
//                                ForEach(group.rows) { row in
//                                    VStack(alignment: .leading, spacing: 6) {
//                                        HStack {
//                                            Text(row.itemName)
//                                                .font(.subheadline)
//                                                .fontWeight(.medium)
//                                            Spacer(minLength: 8)
//                                            Text(row.result)
//                                                .font(.subheadline)
//                                                .foregroundStyle(.primary)
//                                        }
//                                        HStack(spacing: 8) {
//                                            StatusPillaa(status: row.status)
//                                            Text(row.conclusion)
//                                                .font(.caption)
//                                                .foregroundStyle(.secondary)
//                                            Spacer()
//                                        }
//                                        if let recommendation = row.recommendation, !recommendation.isEmpty {
//                                            Text(recommendation)
//                                                .font(.caption)
//                                                .foregroundStyle(.secondary)
//                                                .padding(.top, 2)
//                                        }
//
//                                    }
//                                    .padding(.horizontal, 16)
//                                    .padding(.vertical, 10)
//                                    .background(Color(.systemBackground))
//
//                                    if row.id != group.rows.last?.id {
//                                        Divider().padding(.leading, 16)
//                                    }
//                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .navigationTitle("体检项目")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    NavigationStack {
        PhysicalExamListView()
    }
}

struct CollapsibleCardaa<Header: View, Content: View>: View {
    @State private var isOpen = false
    let header: () -> Header
    let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.24)) { isOpen.toggle() }
            } label: {
                header()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 内容容器：高度动画 + 淡入淡出
            ZStack {
                if isOpen {
                    content()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            )
                        )
                }
            }
            .frame(maxHeight: isOpen ? .infinity : 0, alignment: .top) // 高度从内容到 0
            .clipped()
            .animation(.easeInOut(duration: 0.24), value: isOpen)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(.separator), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
        )
    }
}
enum FilterTab: String, CaseIterable, Identifiable {
    case all = "全部"
    case normal = "正常"
    case abnormal = "异常"
    var id: String { rawValue }
}
struct TabChip: View {
    let title: String
    let isOn: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isOn ? Color(.systemBackground) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(isOn ? Color(.separator) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

enum BadgeStyle { case normal, destructive }
struct Badgeaq: View {
    let text: String
    var style: BadgeStyle = .normal
    var body: some View{
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background( RoundedRectangle(cornerRadius: 8)
                .fill(style == .destructive ? Color.red.opacity(0.12) : Color.primary.opacity(0.06)) )
            .overlay( RoundedRectangle(cornerRadius: 8)
                .stroke(style == .destructive ? Color.red.opacity(0.35) : Color.primary.opacity(0.15), lineWidth: 1) )
        .foregroundStyle(style == .destructive ? .red : .primary) }
}


struct GroupIcon: View {
    let name: String
    var body: some View {
        // 简单映射图标
        let system: String
        let tint: Color
        switch name {
        case "一般检查": system = "person.crop.circle"; tint = .purple
        case "内科": system = "heart.text.square"; tint = .purple
        case "口腔科": system = "mouth"; tint = .purple
        case "妇科": system = "figure.and.child.holdinghands"; tint = .purple
        case "血常规", "血糖", "血脂", "肝功能", "肾功能", "血流变", "心肌酶谱": system = "testtube.2"; tint = .red
        case "心电图": system = "heart"; tint = .pink
        case "影像检查": system = "eye"; tint = .blue
        case "超声检查": system = "stethoscope"; tint = .green
        default: system = "doc.text.magnifyingglass"; tint = .gray
        }
        return Image(systemName: system).foregroundStyle(tint)
    }
}



//
//// MARK: - 颜色与徽标
//
//struct RowPalette {
//    let bg: Color
//    let border: Color
//    let fg: Color
//    let icon: String
//    init(normal: Bool) {
//        if normal {
//            // 对应：border-green-200 bg-green-50 text-green-700
//            bg = Color.green.opacity(0.08)
//            border = Color.green.opacity(0.35)
//            fg = Color.green
//            icon = "checkmark.circle"
//        } else {
//            // 对应异常卡片（可按需换成黄色/红色）
//            bg = Color.red.opacity(0.08)
//            border = Color.red.opacity(0.35)
//            fg = Color.red
//            icon = "exclamationmark.triangle"
//        }
//    }
//}
//
//struct OutlineBadge: View {
//    let text: String
//    let fg: Color
//    let bg: Color
//    let border: Color
//    var body: some View {
//        Text(text)
//            .font(.caption)
//            .padding(.horizontal, 8).padding(.vertical, 4)
//            .background(RoundedRectangle(cornerRadius: 8).fill(bg))
//            .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: 1))
//            .foregroundStyle(fg)
//    }
//}
//
//// 风险颜色简单映射（可按需细化）
//func riskColors(_ risk: String) -> (fg: Color, bg: Color, border: Color) {
//    switch risk {
//    case "低风险":
//        return (.green, Color.green.opacity(0.12), Color.green.opacity(0.35))
//    case "中风险":
//        return (.orange, Color.orange.opacity(0.12), Color.orange.opacity(0.35))
//    case "高风险":
//        return (.red, Color.red.opacity(0.12), Color.red.opacity(0.35))
//    default:
//        return (.secondary, Color.primary.opacity(0.06), Color.primary.opacity(0.15))
//    }
//}
//
//// MARK: - 单条行卡片（对齐 HTML：左侧图标 + 标题/徽标，右侧结果）
//struct StatusPillaa: View {
//    let row: ExamItemaaa
//    var status: ExamStatus {
//        row.status
//    }
//    var body: some View {
//        let isNormal = (row.status != .异常)
//
//        let risk = riskColors(row.riskLevel ?? "低风险")
//
//        let color: Color = (status == .异常) ? .red : .green
//       
//        return HStack(spacing: 8) {
//            if !row.conclusion.isEmpty {
//                Text(row.conclusion)
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//            
//            OutlineBadge(
//                text: row.riskLevel ?? (isNormal ? "低风险" : "中风险"),
//                fg: risk.fg,
//                bg: risk.bg,
//                border: risk.border
//            )
//        }
//    }
//}
//struct ExamRowCard: View {
//    let row: ExamItemaaa   // 你的模型：包含 itemName/result/status/conclusion/recommendation/riskLevel
//
//    var body: some View {
//        let isNormal = (row.status != .异常)
//        let palette = RowPalette(normal: isNormal)
//        let risk = riskColors(row.riskLevel ?? "低风险")
//
//        HStack{
//            Image(systemName: palette.icon)
//                .font(.footnote)
//                .foregroundStyle(palette.fg)
//            VStack(alignment: .leading, spacing: 8) {
//                // 顶部：左信息 + 右结果
//                HStack(alignment: .top) {
//            
//                    HStack(spacing: 8) {
//                       
//
//                        VStack(alignment: .leading, spacing: 4) {
//                            // 标题
//                            Text(row.itemName)
//                                .font(.subheadline).fontWeight(.medium)
//
//                        }
//                    }
//
//                    Spacer()
//                    // 右上角结果
//                    Text(row.result)
//                        .font(.subheadline)
//                        .foregroundStyle(.primary)
//                        .multilineTextAlignment(.trailing)
//                }
//                StatusPillaa(row: row)
//                if let recommendation = row.recommendation, !recommendation.isEmpty {
//                    Text(recommendation)
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//            }
//        }
//        .padding(12)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(palette.bg)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(palette.border, lineWidth: 1)
//                )
//        )
//        .foregroundStyle(palette.fg) // 仅影响图标和绿色主色，正文已分别设置
//    }
//}

// MARK: - 模型辅助（按你现有字段名做最小假设）



// MARK: - 语义色板与 Badge

private struct RowPalette {
    let bg: Color, border: Color, accent: Color, icon: String

    static func forStatus(_ normal: Bool) -> RowPalette {
        normal
        ? .init(bg: .green.opacity(0.08),
                border: .green.opacity(0.35),
                accent: .green,
                icon: "checkmark.circle")
        : .init(bg: .red.opacity(0.08),
                border: .red.opacity(0.35),
                accent: .red,
                icon: "exclamationmark.triangle")
    }
}

private struct OutlineBadge: View {
    let text: String
    let fg: Color
    let bg: Color
    let border: Color
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(bg))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: 1))
            .foregroundStyle(fg)
    }
}

private func riskColors(_ risk: String) -> (fg: Color, bg: Color, border: Color) {
    switch risk {
    case "低风险": return (.green, .green.opacity(0.12), .green.opacity(0.35))
    case "中风险": return (.orange, .orange.opacity(0.12), .orange.opacity(0.35))
    case "高风险": return (.red, .red.opacity(0.12), .red.opacity(0.35))
    default:       return (.secondary, .primary.opacity(0.06), .primary.opacity(0.15))
    }
}

// MARK: - 小组件

private struct StatusAndRiskLine: View {
    let status: ExamStatus
    let conclusion: String
    let riskLevelText: String

    var body: some View {
        let risk = riskColors(riskLevelText)
        HStack(spacing: 8) {
            // 状态 Pills：与 HTML 中“正常/异常”徽标效果一致（次要说明文字）
            if !conclusion.isEmpty {
                Text(conclusion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            OutlineBadge(text: riskLevelText, fg: risk.fg, bg: risk.bg, border: risk.border)
            Spacer(minLength: 0)
        }
    }
}

// 左侧小图标
private struct RowLeadingIcon: View {
    let palette: RowPalette
    var body: some View {
        Image(systemName: palette.icon)
            .font(.headline)
            .foregroundStyle(palette.accent)
    }
}

// 建议提示块（HTML 的“建议：”白底半透明 + 左边框）
private struct RecommendationNote: View {
    let text: String
    let accent: Color
    var body: some View {
        HStack{
            Text("建议：\(text)")
            // 单独写成一个 Text，避免编译器在超长表达式中卡顿
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
                .background(Color.white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(accent)
                                    .frame(width: 3)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            }
            Spacer(minLength: 0)
        }
        .background(Color.white.opacity(0.5))
//        Text("建议：\(text)")
//        // 单独写成一个 Text，避免编译器在超长表达式中卡顿
//            .font(.caption)
//            .foregroundStyle(.secondary)
//            .padding(8)
//            .background(Color.white.opacity(0.5))
//            .clipShape(RoundedRectangle(cornerRadius: 6))
//            .overlay(alignment: .leading) {
//                Rectangle()
//                    .fill(accent)
//                    .frame(width: 3)
//                    .clipShape(RoundedRectangle(cornerRadius: 2))
//            }
    }
}

// MARK: - 行卡片（与 HTML 结构一致：左图标+标题/徽标，右上结果）

struct ExamRowCard: View {
    let row: ExamItemaaa

    var body: some View {
        let isNormal = (row.status != .异常)
        let palette  = RowPalette.forStatus(isNormal)
        let riskText = row.riskLevel ?? (isNormal ? "低风险" : "中风险")

        VStack(alignment: .leading, spacing: 8) {
            // 顶部：左信息 + 右结果
            HStack(alignment: .center, spacing: 8) {
                RowLeadingIcon(palette: palette)

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.itemName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // “正常/异常 + 风险”行
                    StatusAndRiskLine(
                        status: row.status,
                        conclusion: row.status == .正常 ? "正常" : "异常",
                        riskLevelText: riskText
                    )
                }

                Spacer(minLength: 8)

                Text(row.result)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
            }

            if let rec = row.recommendation, !rec.isEmpty && row.status != .正常 {
                RecommendationNote(text: rec, accent: palette.accent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.bg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1))
        )
        .foregroundStyle(palette.accent) // 只着色左侧图标与强调色
    }
}
