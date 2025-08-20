//
//  ExamResultView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/20.
//

import SwiftUI

import SwiftUI

// MARK: - 数据模型

enum ExamAbnormalStatus: String, Codable, CaseIterable {
    case normal, low, medium, high
}

enum ExamSeverity: String, Codable, CaseIterable {
    case low, medium, high
}

struct ExamItem: Identifiable, Codable {
    let id: String
    let category: String        // 大类：血液检查 / 影像检查 / …
    let subcategory: String     // 小类：血脂 / 一般检查 / …
    let itemName: String        // 项目名：总胆固醇 / BMI …
    let result: String          // 结果值：7.73 / 阳性 …
    let unit: String?           // 单位：mmol/L / mmHg / nil
    let referenceRange: String? // 参考值：< 5.7 / 18.5-24.9 …
    let status: ExamAbnormalStatus
    let description: String?    // 简介/解释
    let recommendation: String? // 建议
    let severity: ExamSeverity? // 风险等级（可与status并存，用于样式）
}

struct ExamReportMeta {
    var patientName: String
    var relation: String
    var age: Int
    var gender: String
    var scene: String              // 年度体检
    var examDate: Date
    var hospital: String
    var confidence: Int
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

// MARK: - 配色 & 工具

extension ExamAbnormalStatus {
    var color: Color {
        switch self {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .yellow
        case .normal: return .green
        }
    }
}

fileprivate let dateF: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

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
                                BasicItemCell(item: item)
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
            Badge(text: "置信度 \(result.meta.confidence)%", bg: .green.opacity(0.15), fg: .green)
        }
        .font(.subheadline)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.35)))
    }
    
    private var patientCard: some View {
        Card {
            HStack(spacing: 12) {
                AvatarView(text: String(result.meta.patientName.prefix(2)), bg: .blue.opacity(0.15), fg: .blue)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(result.meta.patientName).font(.headline)
                        Badge(text: result.meta.relation)
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
        Card(tint: .red.opacity(0.08), border: .red.opacity(0.35)) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("发现 \(result.abnormalCount) 项异常")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
                Spacer()
                Badge(text: "需关注", bg: .red.opacity(0.15), fg: .red)
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

struct Card<Content: View>: View {
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

struct Badge: View {
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
        Card(tint: tint.opacity(0.07), border: tint.opacity(0.35)) {
            Button {
                withAnimation(.easeInOut) { isOpen.toggle() }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: icon).foregroundStyle(tint)
                        Text(title).foregroundStyle(tint)
                        Badge(text: "\(count)项", bg: tint.opacity(0.15), fg: tint)
                    }
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down").foregroundStyle(tint)
                }
            }
            .buttonStyle(.plain)
            
            if isOpen {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.top, 4)
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
        Card {
            Button {
                withAnimation(.easeInOut) { isOpen.toggle() }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: icon).foregroundStyle(tint)
                        Text(title).foregroundStyle(.primary)
                        Badge(text: badge, bg: Color(.secondarySystemBackground), fg: .primary)
                    }
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isOpen {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.25)))
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

struct SummaryRow: View {
    let total: Int
    let normal: Int
    let abnormal: Int
    var onTap: () -> Void
    var body: some View {
        Card {
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
        Card(tint: .blue.opacity(0.06), border: .blue.opacity(0.25)) {
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
        Card(tint: .yellow.opacity(0.08), border: .yellow.opacity(0.3)) {
            Text("【免责声明】以上分析仅供参考，不能替代专业医生的诊断。请根据体检结果的异常程度及时就医咨询，特别是高风险项目需要尽快专科就诊。")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

// MARK: - 示例数据 & 预览

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

#Preview {
    NavigationStack {
        ExamResultView(result: .demo)
    }
}
