//
//  ExamResultView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/20.
//

import SwiftUI

import SwiftUI

// MARK: - 数据模型
//
//enum ExamAbnormalStatus: String, Codable, CaseIterable {
//    case normal, low, medium, high
//}
//
//enum ExamSeverity: String, Codable, CaseIterable {
//    case low, medium, high
//}
//
//struct ExamItem: Identifiable, Codable {
//    let id: String
//    let category: String        // 大类：血液检查 / 影像检查 / …
//    let subcategory: String     // 小类：血脂 / 一般检查 / …
//    let itemName: String        // 项目名：总胆固醇 / BMI …
//    let result: String          // 结果值：7.73 / 阳性 …
//    let unit: String?           // 单位：mmol/L / mmHg / nil
//    let referenceRange: String? // 参考值：< 5.7 / 18.5-24.9 …
//    let status: ExamAbnormalStatus
//    let description: String?    // 简介/解释
//    let recommendation: String? // 建议
//    let severity: ExamSeverity? // 风险等级（可与status并存，用于样式）
//}
//
//struct ExamReportMeta {
//    var patientName: String
//    var relation: String
//    var age: Int
//    var gender: String
//    var scene: String              // 年度体检
//    var examDate: Date
//    var hospital: String
//    var confidence: Int
//}
//
//struct ExamSection: Identifiable {
//    let id = UUID()
//    let title: String
//    let icon: String
//    let tint: Color
//    var items: [ExamItem]
//    var badgeText: String { "\(items.count)项" }
//}
//
//struct ExamReportResult {
//    var meta: ExamReportMeta
//    var highRisk: [ExamItem]
//    var midRisk: [ExamItem]
//    var lowRisk: [ExamItem]
//    var normalCount: Int
//    var abnormalCount: Int
//    var totalCount: Int { normalCount + abnormalCount }
//    var sections: [ExamSection]
//    var suggestions: [String]
//}
//
//// MARK: - 配色 & 工具
//
//extension ExamAbnormalStatus {
//    var color: Color {
//        switch self {
//        case .high:   return .red
//        case .medium: return .orange
//        case .low:    return .yellow
//        case .normal: return .green
//        }
//    }
//}
//
fileprivate let dateF: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f
}()


// MARK: - 1) 升级本地模型

/// 原来只有 normal/low/medium/high；为适配 JSON，补充 abnormal
enum ExamAbnormalStatus: String, Codable, CaseIterable {
    case normal
    case low
    case medium
    case high
    case abnormal       // 非方向性异常（如影像“阳性/阴性”）
}

enum ExamSeverity: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low:
            return .yellow      // 低风险 → 绿色
        case .medium:
            return .orange     // 中风险 → 橙色
        case .high:
            return .red        // 高风险 → 红色
        }
    }
}
struct ExamItem: Identifiable, Codable {
    let id: String
    let category: String
    let subcategory: String
    let itemName: String
    let result: String
    let unit: String?
    let referenceRange: String?
    let status: ExamAbnormalStatus
    let description: String?
    let recommendation: String?
    let severity: ExamSeverity?
}

struct ExamReportMeta {
    var patientName: String
    var relation: String
    var age: Int
    var gender: String
    var scene: String
    var examDate: Date
    var hospital: String
    var confidence: Int    // 0~100
}

struct ExamSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    var items: [ExamItem]
    var badgeText: String { "\(items.count)项" }
}

struct ExamReportResult {
    var meta: ExamReportMeta
    var highRisk: [ExamItem]
    var midRisk: [ExamItem]
    var lowRisk: [ExamItem]
    var normalCount: Int
    var abnormalCount: Int
    var totalCount: Int { normalCount + abnormalCount }
    var sections: [ExamSection]
    var suggestions: [String]
}

// MARK: - 2) DTO（对齐你给的 JSON 字段）

// MARK: - API DTO
private struct ApiExamReport: Decodable {
    let patientName: String
    let age: Int
    let gender: String
    let relationship: String
    let examType: String
    let examDate: String
    let institution: String
    let abnormalCount: Int
    let totalItems: Int
    let normalItems: Int
    let abnormalItems: [ApiAbnormalItem]
    let confidence: Double
}

private struct ApiAbnormalItem: Decodable {
    let id: String
    let category: String
    let subcategory: String
    let itemName: String
    let result: String
    let unit: String?
    let referenceRange: String?
    let status: String          // "high" | "abnormal" | ...
    let description: String?
    let recommendation: String?
    let severity: String?       // "low" | "medium" | "high"
}

// MARK: - 映射辅助
private let apiDateF: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = .init(identifier: "zh_CN")
    return f
}()

extension ExamAbnormalStatus {
    static func fromApi(_ raw: String) -> ExamAbnormalStatus {
        switch raw.lowercased() {
        case "normal":  return .normal
        case "low":     return .low
        case "medium":  return .medium
        case "high":    return .high
        case "abnormal","阳性","pos": return .abnormal
        default:        return .abnormal
        }
    }
}

extension ExamSeverity {
    static func fromApi(_ raw: String?) -> ExamSeverity? {
        switch raw?.lowercased() {
        case "low": return .low
        case "medium": return .medium
        case "high": return .high
        default: return nil
        }
    }
}

private extension ExamItem {
    static func fromApi(_ a: ApiAbnormalItem) -> ExamItem {
        .init(id: a.id,
              category: a.category,
              subcategory: a.subcategory,
              itemName: a.itemName,
              result: a.result,
              unit: a.unit,
              referenceRange: a.referenceRange,
              status: .fromApi(a.status),
              description: a.description,
              recommendation: a.recommendation,
              severity: .fromApi(a.severity))
    }
}

private extension ExamReportResult {
    static func fromApi(_ api: ApiExamReport) -> ExamReportResult {
        let items = api.abnormalItems.map(ExamItem.fromApi)

        // 风险桶
        let high = items.filter { $0.severity == .high }
        let mid  = items.filter { $0.severity == .medium }
        let low  = items.filter { $0.severity == .low }

        // meta
        let meta = ExamReportMeta(
            patientName: api.patientName,
            relation: api.relationship,
            age: api.age,
            gender: api.gender,
            scene: api.examType,
            examDate: apiDateF.date(from: api.examDate) ?? Date(),
            hospital: api.institution,
            confidence: max(0, min(100, Int(round(api.confidence * 100))))
        )

        // Section 按 category 聚合（UI 用到哪些就列哪些）
        func section(_ title: String, icon: String, tint: Color) -> ExamSection {
            .init(title: title, icon: icon, tint: tint, items: items.filter { $0.category == title })
        }

        let sections: [ExamSection] = [
            section("体格检查", icon: "waveform", tint: .purple),
            section("血液检查", icon: "testtube.2", tint: .red),
            section("影像检查", icon: "eye", tint: .blue),
            section("超声检查", icon: "stethoscope", tint: .green),
            section("心电图", icon: "heart",tint: .pink)
        ]

        return .init(
            meta: meta,
            highRisk: high,
            midRisk: mid,
            lowRisk: low,
            normalCount: api.normalItems,
            abnormalCount: api.abnormalCount,
            sections: sections,
            suggestions: [
                "重点关注：血脂异常和高血压需积极治疗，建议心内科就诊",
                "生活调理：控制体重，低盐低脂饮食，适量运动",
                "定期复查：建议3-6个月复查相关异常项目",
                "专科随诊：结节/增生类项目建议按医嘱随访"
            ]
        )
    }
}

//struct ApiExamReport: Decodable {
//    let patientName: String
//    let age: Int
//    let gender: String
//    let relationship: String
//    let examType: String
//    let examDate: String
//    let institution: String
//    let abnormalCount: Int
//    let totalItems: Int
//    let normalItems: Int
//    let abnormalItems: [ApiAbnormalItem]
//    let confidence: Double
//}
//
//struct ApiAbnormalItem: Decodable, Identifiable {
//    let id: String
//    let category: String
//    let subcategory: String
//    let itemName: String
//    let result: String
//    let unit: String?
//    let referenceRange: String?
//    let status: String          // "high" | "abnormal" ...
//    let description: String?
//    let recommendation: String?
//    let severity: String?       // "low" | "medium" | "high"
//}
//
//// MARK: - 3) 映射：Api → 本地模型
//
//fileprivate let apiDateF: DateFormatter = {
//    let f = DateFormatter()
//    f.dateFormat = "yyyy-MM-dd"
//    f.locale = .init(identifier: "zh_CN")
//    return f
//}()
//
//extension ExamAbnormalStatus {
//    static func fromApi(_ raw: String) -> ExamAbnormalStatus {
//        // 允许大小写/中英文穿插的容错
//        switch raw.lowercased() {
//        case "high", "↑", "highrisk": return .high
//        case "low", "↓":              return .low
//        case "medium", "mid":         return .medium
//        case "normal":                return .normal
//        case "abnormal", "pos", "阳性": return .abnormal
//        default:                      return .abnormal
//        }
//    }
//}
//
//extension ExamSeverity {
//    static func fromApi(_ raw: String?) -> ExamSeverity? {
//        guard let r = raw?.lowercased() else { return nil }
//        switch r {
//        case "high":   return .high
//        case "medium": return .medium
//        case "low":    return .low
//        default:       return nil
//        }
//    }
//}
//
//extension ExamItem {
//    static func fromApi(_ a: ApiAbnormalItem) -> ExamItem {
//        .init(id: a.id,
//              category: a.category,
//              subcategory: a.subcategory,
//              itemName: a.itemName,
//              result: a.result,
//              unit: a.unit,
//              referenceRange: a.referenceRange,
//              status: .fromApi(a.status),
//              description: a.description,
//              recommendation: a.recommendation,
//              severity: .fromApi(a.severity))
//    }
//}
//
//extension ExamReportResult {
//    /// 把一整个 JSON 映射成可直接喂给 UI 的结果对象
//    static func fromApi(_ api: ApiExamReport) -> ExamReportResult {
//        let items = api.abnormalItems.map(ExamItem.fromApi)
//
//        // 分组到 UI 的 section（按 category）
//        func sec(_ title: String, icon: String, tint: Color) -> ExamSection {
//            let arr = items.filter { $0.category == title }
//            return .init(title: title, icon: icon, tint: tint, items: arr)
//        }
//
//        // 风险分桶（按 severity）
//        let high = items.filter { $0.severity == .high }
//        let mid  = items.filter { $0.severity == .medium }
//        let low  = items.filter { $0.severity == .low }
//
//        // 置信度百分比
//        let conf = max(0, min(100, Int(round(api.confidence * 100))))
//
//        let meta = ExamReportMeta(
//            patientName: api.patientName,
//            relation: api.relationship,
//            age: api.age,
//            gender: api.gender,
//            scene: api.examType,
//            examDate: apiDateF.date(from: api.examDate) ?? Date(),
//            hospital: api.institution,
//            confidence: conf
//        )
//
//        // 你页面里的这些分类与图标颜色（可按需调整）
//        let sections: [ExamSection] = [
//            sec("体格检查", icon: "waveform",     tint: .purple),
//            sec("血液检查", icon: "testtube.2",   tint: .red),
//            sec("影像检查", icon: "eye",          tint: .blue),
//            sec("超声检查", icon: "stethoscope",  tint: .green),
//            sec("心电图",   icon: "heart",        tint: .pink)
//        ]
//
//        // 建议可以由服务器返回；这里给一些兜底
//        let tips = [
//            "重点关注：根据高风险项目尽快至相应专科就诊",
//            "生活调理：低盐低脂饮食，控制体重，规律运动",
//            "定期复查：建议3-6个月复查异常项目"
//        ]
//
//        return .init(
//            meta: meta,
//            highRisk: high,
//            midRisk: mid,
//            lowRisk: low,
//            normalCount: api.normalItems,
//            abnormalCount: api.abnormalCount,
//            sections: sections,
//            suggestions: tips
//        )
//    }
//}

// MARK: - 4) 用法示例（把你给的 JSON 塞进来）

// 假设你从服务端拿到 Data（或你也可以直接把上面的对象用 Codable 手动构）：
func buildResultFromServerData(_ data: Data) throws -> ExamReportResult {
    let decoder = JSONDecoder()
    let api = try decoder.decode(ApiExamReport.self, from: data)
    return ExamReportResult.fromApi(api)
}

// 或者直接把你给的字典转 Data 解码：
func buildResultFromDictionary(_ dict: [String: Any]) throws -> ExamReportResult {
    let data = try JSONSerialization.data(withJSONObject: dict, options: [])
    return try buildResultFromServerData(data)
}

// MARK: - 视图

struct ExamResultView: View {
    let result: ExamReportResult
    @State private var openHigh = true
    @State private var openPhysical = false
    @State private var openBlood = false
    @State private var openImaging = false
    @State private var openUltrasound = false
    @State private var openECG = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                successBanner
                
                patientCard
                
                abnormalOverviewCard
                
                // 高风险分组（单独样式）
                if !result.highRisk.isEmpty {
                    RiskCollapsibleCard(
                        title: "高风险项目",
                        count: result.highRisk.count,
                        icon: "exclamationmark.triangle.fill",
                        tint: .red,
                        isOpen: $openHigh
                    ) {
                        VStack(spacing: 8) {
                            ForEach(result.highRisk) { item in
                                RiskItemCell(item: item)
                            }
                        }
                    }
                }
                
                // 其他分组
                ForEach(result.sections) { section in
                    CollapsibleCard(
                        title: section.title,
                        icon: section.icon,
                        tint: section.tint,
                        badge: section.badgeText,
                        isOpen: binding(for: section.title)
                    ) {
                        VStack(spacing: 8) {
                            ForEach(section.items) { item in
//                                BasicItemCell(item: item)
                                RiskItemCell(item: item)
                            }
                        }
                    }
                }
                
                // 汇总与跳转
                SummaryRowa(total: result.totalCount, normal: result.normalCount, abnormal: result.abnormalCount) {
                    // 查看详情 action
                }
                
                // 综合建议
                SuggestionsCard(suggestions: result.suggestions)
                
                // 免责声明
                DisclaimerCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("体检报告")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 子视图块
    
    private var successBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.badge.checkmark")
                .foregroundStyle(.green)
            Text("识别成功")
                .foregroundStyle(Color.green.opacity(0.9))
            Spacer()
            Badgea(text: "置信度 \(result.meta.confidence)%", bg: .green.opacity(0.15), fg: .green)
        }
        .font(.subheadline)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.35)))
    }
    
    private var patientCard: some View {
        Cardea {
            HStack(spacing: 12) {
                AvatarView(text: String(result.meta.patientName.prefix(2)), bg: .blue.opacity(0.15), fg: .blue)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(result.meta.patientName).font(.headline)
                        Badgea(text: result.meta.relation)
                    }
                    Text("\(result.meta.age)岁 · \(result.meta.gender)")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                IconLine(icon: "waveform.path.ecg", tint: .blue, text: result.meta.scene)
                IconLine(icon: "calendar", tint: .blue, text: dateF.string(from: result.meta.examDate))
                IconLine(icon: "building.2", tint: .blue, text: result.meta.hospital)
            }
        }
    }
    
    private var abnormalOverviewCard: some View {
        Cardea(tint: .red.opacity(0.08), border: .red.opacity(0.35)) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("发现 \(result.abnormalCount) 项异常")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
                Spacer()
                Badgea(text: "需关注", bg: .red.opacity(0.15), fg: .red)
            }
            .padding(.bottom, 6)
            
            HStack {
                StatTile(value: count(result.highRisk), label: "高风险", tint: .red)
                Divider().frame(height: 32)
                StatTile(value: count(result.midRisk), label: "中风险", tint: .orange)
                Divider().frame(height: 32)
                StatTile(value: count(result.lowRisk), label: "低风险", tint: .yellow)
            }
            .padding(.top, 2)
        }
    }
    
    private func count(_ arr: [ExamItem]) -> Int { arr.count }
    
    private func binding(for title: String) -> Binding<Bool> {
        switch title {
        case "体格检查":  return $openPhysical
        case "血液检查":  return $openBlood
        case "影像检查":  return $openImaging
        case "超声检查":  return $openUltrasound
        case "心电图":    return $openECG
        default:          return .constant(false)
        }
    }
}

// MARK: - 复用组件

struct Cardea<Content: View>: View {
    var tint: Color = Color(.systemBackground)
    var border: Color = Color(.separator).opacity(0.4)
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(tint))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(border))
    }
}

struct Badgea: View {
    var text: String
    var bg: Color = Color(.secondarySystemBackground)
    var fg: Color = .primary
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(bg))
            .foregroundStyle(fg)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(bg.opacity(0.6)))
    }
}

struct AvatarView: View {
    var text: String
    var bg: Color
    var fg: Color
    var body: some View {
        ZStack {
            Circle().fill(bg)
            Text(text).font(.subheadline).foregroundStyle(fg)
        }
    }
}

struct IconLine: View {
    let icon: String
    let tint: Color
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(text).foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}

struct StatTile: View {
    let value: Int
    let label: String
    let tint: Color
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.title3).bold().foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(tint.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
    }
}

struct RiskCollapsibleCard<Content: View>: View {
    let title: String
    let count: Int
    let icon: String
    let tint: Color
    @Binding var isOpen: Bool
    @ViewBuilder var content: Content
    
    var body: some View {
        Cardea(tint: tint.opacity(0.07), border: tint.opacity(0.35)) {
            Button {
                withAnimation(.easeInOut) { isOpen.toggle() }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: icon).foregroundStyle(tint)
                        Text(title).foregroundStyle(tint)
                        Badgea(text: "\(count)项", bg: tint.opacity(0.15), fg: tint)
                    }
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down").foregroundStyle(tint)
                }
            }
            .buttonStyle(.plain)
            
            if isOpen {
                if isOpen {
                    content
                        .fixedSize(horizontal: false, vertical: true) // 内容决定高度
                        .transition(.opacity.combined(with: .modifier(
                            active: HeightCollapseModifier(isCollapsed: true),
                            identity: HeightCollapseModifier(isCollapsed: false)
                        )))
                        .padding(.top, 4)
                }

            }
        }
    }
}
struct HeightCollapseModifier: ViewModifier {
    let isCollapsed: Bool
    
    func body(content: Content) -> some View {
        Group {
            if isCollapsed {
                content
                    .frame(height: 0)
                    .clipped()
            } else {
                content
            }
        }
    }
}


struct CollapsibleCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    let badge: String
    @Binding var isOpen: Bool
    @ViewBuilder var content: Content
    
    var body: some View {
        Cardea {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isOpen.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: icon).foregroundStyle(tint)
                        Text(title).foregroundStyle(.primary)
                        Badgea(text: badge,
                               bg: Color(.secondarySystemBackground),
                               fg: .primary)
                    }
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .background(Color.clear)
            }
            .buttonStyle(.plain)

            if isOpen {
                content
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                        )
                    )
                    .padding(.top, 4)
            }
        }

    }
}

struct RiskItemCell: View {
    let item: ExamItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.forward").foregroundStyle(.red)
                        Text(item.itemName).font(.subheadline).bold()
                    }
                    Text(item.subcategory).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Text(item.result).font(.subheadline)
                        if let unit = item.unit, !unit.isEmpty {
                            Text(unit).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let ref = item.referenceRange {
                        Text("参考：\(ref)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            if let desc = item.description, !desc.isEmpty {
                Text(desc).font(.caption).foregroundStyle(.primary.opacity(0.8))
            }
            if let rec = item.recommendation, !rec.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Rectangle().fill(.red).frame(width: 2)
                    Text("建议：\(rec)").font(.caption)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.25)))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(item.severity?.color.opacity(0.06) ?? Color.red.opacity(0.06))
        )

        .overlay(RoundedRectangle(cornerRadius: 10).stroke(item.severity?.color.opacity(0.25) ?? Color.red.opacity(0.25)))
    }
}

struct BasicItemCell: View {
    let item: ExamItem
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.itemName).font(.subheadline).bold()
                    Text(item.subcategory).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Text(item.result).font(.subheadline)
                        if let unit = item.unit, !unit.isEmpty {
                            Text(item.unit!).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let ref = item.referenceRange {
                        Text("参考：\(ref)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Divider().opacity(0.08)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
}

struct SummaryRowa: View {
    let total: Int
    let normal: Int
    let abnormal: Int
    var onTap: () -> Void
    var body: some View {
        Cardea {
            HStack {
                Text("共\(total)项 · 正常\(normal)项 · 异常\(abnormal)项")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("查看详情 →", action: onTap)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

struct SuggestionsCard: View {
    let suggestions: [String]
    var body: some View {
        Cardea(tint: .blue.opacity(0.06), border: .blue.opacity(0.25)) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill").foregroundStyle(.blue)
                Text("综合健康建议").font(.subheadline).bold()
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(suggestions, id: \.self) { s in
                    Text("• \(s)").font(.subheadline).foregroundStyle(.blue.opacity(0.9))
                }
            }
        }
    }
}

struct DisclaimerCard: View {
    var body: some View {
        Cardea(tint: .yellow.opacity(0.08), border: .yellow.opacity(0.3)) {
            Text("【免责声明】以上分析仅供参考，不能替代专业医生的诊断。请根据体检结果的异常程度及时就医咨询，特别是高风险项目需要尽快专科就诊。")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}



#Preview {
    NavigationStack {
        ExamResultView(result: .demoa)
    }
}



let json = """
{
    "patientName": "王玉兰",
    "age": 56,
    "gender": "女",
    "relationship": "妈妈",
    "examType": "年度体检",
    "examDate": "2024-08-15",
    "institution": "市第一人民医院",
    "abnormalCount": 19,
    "totalItems": 50,
    "normalItems": 31,
    "confidence": 0.91,
    "abnormalItems": [
        {
            "id": "1",
            "category": "体格检查",
            "subcategory": "一般检查",
            "itemName": "超重",
            "result": "26.23",
            "unit": "Kg/㎡",
            "referenceRange": "18.5-24.9",
            "status": "high",
            "description": "体重指数超标，属于超重范围",
            "recommendation": "节制饮食，适量运动，控制体重",
            "severity": "medium"
        },
        {
            "id": "2",
            "category": "血液检查",
            "subcategory": "血脂",
            "itemName": "总胆固醇",
            "result": "7.73",
            "unit": "mmol/L",
            "referenceRange": "<5.7",
            "status": "high",
            "description": "血脂异常多由饮食不当、饮酒、缺少运动、糖尿病等引起。长期血脂异常会导致动脉粥样硬化，引发心脑血管疾病。",
            "recommendation": "积极控制诱发因素，定期复查。平时应注意控制主食量，保持低脂低糖饮食，忌烟酒，加强体育锻炼。若经严格生活干预，血脂仍明显异常，应在医生指导下药物降脂治疗。",
            "severity": "high"
        },
        {
            "id": "3",
            "category": "血液检查",
            "subcategory": "血脂",
            "itemName": "低密度脂蛋白胆固醇",
            "result": "3.60",
            "unit": "mmol/L",
            "referenceRange": "<3.37",
            "status": "high",
            "description": "低密度脂蛋白胆固醇偏高",
            "recommendation": "配合总胆固醇的治疗方案",
            "severity": "high"
        },
        {
            "id": "4",
            "category": "体格检查",
            "subcategory": "内科",
            "itemName": "高血压",
            "result": "130/68",
            "unit": "mmHg",
            "referenceRange": "<120/80",
            "status": "high",
            "description": "既往高血压，已服药。长期持续高血压，会导致动脉硬化，引发心、脑、肾等器官的病变。",
            "recommendation": "在医生指导下按时服药，平时应低盐低脂饮食，适度有氧运动，控制体重，戒烟限酒，规律休息，监测血压。",
            "severity": "high"
        },
        {
            "id": "5",
            "category": "影像检查",
            "subcategory": "CT检查",
            "itemName": "多灶性腔隙性脑梗塞",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "脑部小血管病变",
            "recommendation": "必要时请MR检查",
            "severity": "high"
        },
        {
            "id": "6",
            "category": "影像检查",
            "subcategory": "CT检查",
            "itemName": "副鼻窦炎",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "鼻窦炎症",
            "recommendation": "随诊",
            "severity": "low"
        },
        {
            "id": "7",
            "category": "体格检查",
            "subcategory": "口腔科",
            "itemName": "牙结石",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "口腔卫生问题",
            "recommendation": "可以到医院口腔科做超声波洁治",
            "severity": "low"
        },
        {
            "id": "8",
            "category": "超声检查",
            "subcategory": "彩超",
            "itemName": "左侧叶甲状腺囊性结节",
            "result": "TI-RADS 2级",
            "referenceRange": "无结节",
            "status": "abnormal",
            "description": "常见如甲状腺退行性变、炎症、自身免疫以及新生物等都可以表现为结节。",
            "recommendation": "定期复查超声，医院内分泌科或外科进一步检查",
            "severity": "medium"
        },
        {
            "id": "9",
            "category": "心电图",
            "subcategory": "静态心电图",
            "itemName": "肢体导联低电压",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "少数可见于正常人或体形肥胖者，亦可见于心肌炎、肺心病、心包积液、心肌损害等。",
            "recommendation": "医院心内科随诊",
            "severity": "medium"
        },
        {
            "id": "10",
            "category": "心电图",
            "subcategory": "静态心电图",
            "itemName": "T波改变",
            "result": "轻度改变(V4、V5、V6)",
            "referenceRange": "正常",
            "status": "abnormal",
            "description": "常见于健康人群或者各类心脏病患者。",
            "recommendation": "复查心电图，如有不适，应及时到医院就诊。平时避免疲劳、熬夜和酗酒。",
            "severity": "medium"
        },
        {
            "id": "11",
            "category": "影像检查",
            "subcategory": "CT检查",
            "itemName": "两肺上叶慢性炎性病变",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "肺部慢性炎症",
            "recommendation": "与老片比较，定期复查",
            "severity": "medium"
        },
        {
            "id": "12",
            "category": "超声检查",
            "subcategory": "彩超",
            "itemName": "双侧乳腺增生",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "常见原因：①内分泌失调、情绪等精神因素影响。②佩戴过紧的胸罩或穿过紧的内衣等。③长期服用含雌激素的保健品。",
            "recommendation": "定期自我检查、乳腺超声或乳腺钼靶复查，必要时医院乳腺外科随诊。平时保持心情舒畅、劳逸结合、不过多服食含有激素的滋补品和长期使用含有激素成分的化妆品等。",
            "severity": "medium"
        },
        {
            "id": "13",
            "category": "超声检查",
            "subcategory": "彩超",
            "itemName": "胆囊息肉",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "胆囊内息肉样病变",
            "recommendation": "定期复查肝胆超声，必要时肝胆外科就诊",
            "severity": "medium"
        },
        {
            "id": "14",
            "category": "超声检查",
            "subcategory": "彩超",
            "itemName": "胆囊炎",
            "result": "胆囊壁毛糙",
            "referenceRange": "正常",
            "status": "abnormal",
            "description": "胆囊壁毛糙有胆囊炎的可能。",
            "recommendation": "结合临床分析，定期复查。无症状者无需治疗，但应忌酒，避免油腻食物。如有不适，肝胆外科或消化内科诊治。",
            "severity": "medium"
        },
        {
            "id": "15",
            "category": "超声检查",
            "subcategory": "彩超",
            "itemName": "双肾尿盐结晶",
            "result": "多发",
            "referenceRange": "无",
            "status": "abnormal",
            "description": "多因饮水少、久坐缺乏运动等造成，尤以炎热的夏天更易形成。",
            "recommendation": "平时多饮水，多运动，忌饮浓茶及碳酸饮料，定期复查超声，泌尿外科随诊",
            "severity": "medium"
        },
        {
            "id": "16",
            "category": "影像检查",
            "subcategory": "DR检查",
            "itemName": "腰椎骨质增生",
            "result": "阳性",
            "referenceRange": "阴性",
            "status": "abnormal",
            "description": "腰椎间盘退行性变，椎间隙可因之而狭窄，关节突因磨损而产生骨质增生。",
            "recommendation": "戒烟限酒，睡硬板床，加强腰背肌锻炼，可适当理疗、推拿，必要时去骨科或康复科诊治",
            "severity": "medium"
        },
        {
            "id": "17",
            "category": "血液检查",
            "subcategory": "肝功能",
            "itemName": "间接胆红素升高",
            "result": "17.0",
            "unit": "μmol/L",
            "referenceRange": "0-13.7",
            "status": "high",
            "description": "见于肝胆系统疾病，如胆囊炎、胆结石、肝炎、溶血、黄疸等，也可见于劳累、喝水少、饮酒过量。",
            "recommendation": "注意休息，多饮水，忌酒，复查相关项目或医院肝病专科就诊",
            "severity": "medium"
        },
        {
            "id": "18",
            "category": "血液检查",
            "subcategory": "血流变",
            "itemName": "血流变异常",
            "result": "RBC聚集指数6.14，全血切变率21.62",
            "referenceRange": "RBC聚集指数2.98-5.99，全血切变率13.79-20.13",
            "status": "high",
            "description": "血液流变学异常",
            "recommendation": "复查血流变",
            "severity": "medium"
        },
        {
            "id": "19",
            "category": "血液检查",
            "subcategory": "酶学检查",
            "itemName": "乳酸脱氢酶偏高",
            "result": "253.67",
            "unit": "U/L",
            "referenceRange": "120.00-250.00",
            "status": "high",
            "description": "见于肝细胞损害如急、慢性活动性肝炎、肝硬化、肝癌，任何原因引起的溶血（包括采血溶血），心肌梗死、心力衰竭，急性肾盂肾炎，白血病，运动后。",
            "recommendation": "可复查，必要时到医院检查",
            "severity": "medium"
        }
    ]
}
"""


// MARK: - 示例数据 & 预览
// MARK: - 用 JSON 驱动 demo
extension ExamReportResult {
    static let demoJSON: String = json

    static var demoa: ExamReportResult {
        if let data = demoJSON.data(using: .utf8),
           let api = try? JSONDecoder().decode(ApiExamReport.self, from: data) {
            return ExamReportResult.fromApi(api)
        }

        // 兜底：万一解析失败，给一个最小可用的演示
        return .init(
            meta: .init(patientName: "演示", relation: "本人", age: 30, gender: "男",
                        scene: "年度体检", examDate: Date(), hospital: "示例医院", confidence: 90),
            highRisk: [], midRisk: [], lowRisk: [],
            normalCount: 0, abnormalCount: 0,
            sections: [], suggestions: []
        )
    }
}

extension ExamReportResult {
    static var demo: ExamReportResult {
        let high: [ExamItem] = [
            .init(id: "chol",
                  category: "血液检查", subcategory: "血脂",
                  itemName: "总胆固醇", result: "7.73", unit: "mmol/L",
                  referenceRange: "<5.7", status: .high,
                  description: "血脂异常多由饮食、饮酒、缺少运动、糖尿病等引起，长期异常会导致动脉粥样硬化。",
                  recommendation: "控制饮食与体重，戒烟酒，加强运动；必要时在医生指导下药物降脂。",
                  severity: .high),
            .init(id: "ldl",
                  category: "血液检查", subcategory: "血脂",
                  itemName: "低密度脂蛋白胆固醇", result: "3.60", unit: "mmol/L",
                  referenceRange: "<3.37", status: .high,
                  description: "LDL-C 偏高。", recommendation: "配合总胆固醇治疗方案。", severity: .medium),
            .init(id: "bp",
                  category: "体格检查", subcategory: "内科",
                  itemName: "高血压", result: "130/68", unit: "mmHg",
                  referenceRange: "<120/80", status: .high,
                  description: "既往高血压，已服药。长期持续高血压可致动脉硬化等并发症。",
                  recommendation: "按医嘱规律服药，低盐低脂饮食，适度运动，监测血压。", severity: .high),
            .init(id: "ct",
                  category: "影像检查", subcategory: "CT检查",
                  itemName: "多灶性腔隙性脑梗塞", result: "阳性", unit: nil,
                  referenceRange: "阴性", status: .high,
                  description: "脑部小血管病变。", recommendation: "必要时进行 MR 检查。", severity: .high)
        ]
        
        let physical: [ExamItem] = [
            .init(id: "bmi",
                  category: "体格检查", subcategory: "一般检查",
                  itemName: "超重(BMI)", result: "26.23", unit: "kg/㎡",
                  referenceRange: "18.5-24.9", status: .medium,
                  description: "体重指数超标，属于超重范围", recommendation: "节制饮食，适量运动，控制体重", severity: .medium)
        ]
        
        let blood: [ExamItem] = [
            .init(id: "glu", category: "血液检查", subcategory: "血糖",
                  itemName: "空腹血糖", result: "5.1", unit: "mmol/L",
                  referenceRange: "3.9-6.1", status: .normal,
                  description: nil, recommendation: nil, severity: .low)
        ]
        
        let imaging: [ExamItem] = []
        let us: [ExamItem] = []
        let ecg: [ExamItem] = []
        
        return .init(
            meta: .init(patientName: "王玉兰", relation: "妈妈", age: 56, gender: "女",
                        scene: "年度体检", examDate: dateF.date(from: "2024-08-15")!,
                        hospital: "市第一人民医院", confidence: 91),
            highRisk: high,
            midRisk: physical.filter { $0.status == .medium },
            lowRisk: [],
            normalCount: 31,
            abnormalCount: 19,
            sections: [
                .init(title: "体格检查", icon: "waveform", tint: .purple, items: physical),
                .init(title: "血液检查", icon: "testtube.2", tint: .red, items: blood),
                .init(title: "影像检查", icon: "eye", tint: .blue, items: imaging),
                .init(title: "超声检查", icon: "stethoscope", tint: .green, items: us),
                .init(title: "心电图", icon: "heart", tint: .pink, items: ecg)
            ],
            suggestions: [
                "重点关注：血脂异常和高血压需积极治疗，建议心内科就诊",
                "生活调理：控制体重，低盐低脂饮食，适量运动",
                "定期复查：建议3-6个月复查相关异常项目",
                "专科随诊：结节/增生类项目建议按医嘱随访"
            ]
        )
    }
}
