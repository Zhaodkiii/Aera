//
//  CaseCard.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import SwiftUI
import SwiftUI
import Combine

struct CaseCard: View {
    @Binding var item: CaseItem
    var maxChips: Int = 4
    var onTap: (() -> Void)? = nil
    
    // 静态缓存格式器—避免频繁创建
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private var dateText: String { Self.dateFormatter.string(from: item.visitDate) }
    
    // 严重程度样式
    private var style: SeverityStyle { SeverityStyle(severity: item.severity) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                onTap?()
            } label: {
                header
            }
            NavigationLink{
                CaseDetailScreen(patient: .samplePatient, events: CDEventItem.sampleEvents)
            } label: {
                VStack(alignment: .leading, spacing: 12){
       
                    // 主诉
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "stethoscope")
                            .font(.caption)
                            .foregroundStyle(style.accent)
                        Text("主诉：")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(style.accent)
                        Text(item.chiefComplaint)
                            .font(.subheadline)
                            .foregroundStyle(style.textStrong)
                            .lineLimit(2)
                    }
                    
                    // 诊断
                    VStack(alignment: .leading, spacing: 4) {
                        Text("诊断：")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(style.textSecondary)
                        Text(item.diagnosis)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(style.textStrong)
                            .lineLimit(2)
                    }
                    
                    // 症状
                    if !item.symptoms.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("症状：")
                                .font(.subheadline).foregroundStyle(style.textSecondary)
                            TagCloud(
                                items: limitedList(item.symptoms, max: maxChips),
                                extraCount: max(0, item.symptoms.count - maxChips),
                                tint: style.chipBG,
                                fg: style.chipFG
                            )
                        }
                    }
                    
                    // 用药
                    if !item.medications.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "pills.fill")
                                Text("用药：")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(style.textSecondary)
                            
                            TagCloud(
                                items: limitedList(item.medications, max: maxChips),
                                extraCount: max(0, item.medications.count - maxChips),
                                tint: Color.blue.opacity(0.12),
                                fg: .blue
                            )
                        }
                    }
                    
                    // 备注 & 底部
                    VStack(alignment: .leading, spacing: 8) {
                        if !item.notes.isEmpty {
                            Text("“\(item.notes)”")
                                .font(.footnote)
                                .italic()
                                .foregroundStyle(style.accent)
                        }
                        
                        HStack {
                            StatusPill(text: item.status.rawValue, tint: statusTint(item.status))
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(dateText)
                            }
                            .font(.footnote)
                            .foregroundStyle(style.textSecondary)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("最后更新于 \(dateText)")
                        }
                        .padding(.top, 2)
                    }

                }
            }
        }
        .padding(14)
        .frame(height: 360)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(style.cardBG)
        )
        .overlay(alignment: .leading) {
            // 左侧竖条
            Capsule().fill(style.accent).frame(width: 4)
                .padding(.vertical, 10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style.border, lineWidth: 1)
        )

        .buttonStyle(.plain)
        .contextMenu {
            Button("编辑", systemImage: "square.and.pencil", action: {})
            Button("删除", systemImage: "trash", role: .destructive, action: {})
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }
    
    // MARK: Header
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            // 头像（姓名前2字）
            AvatarCircle(text: String(item.patientName.prefix(2)),
                         bg: style.avatarBG,
                         fg: style.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.patientName).font(.headline).foregroundStyle(style.textStrong)
                    Text("\(item.age)岁 · \(item.gender)")
                        .font(.subheadline)
                        .foregroundStyle(style.textSecondary)
                }
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(style.accent)
                    Text(item.relationship)
                        .font(.caption)
                        .foregroundStyle(style.accent)
                    SeverityBadgeCompact(severity: item.severity)
                }
            }
            Spacer(minLength: 8)
            // 收藏
            Button {
                item.isFavorite.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(item.isFavorite ? .yellow : style.textSecondary)
                    .padding(6)
                    .background(.white.opacity(0.4), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isFavorite ? "取消收藏" : "设为收藏")
        }
    }
    
    // MARK: Helpers
    private func limitedList(_ arr: [String], max: Int) -> [String] {
        Array(arr.prefix(max))
    }
    private func statusTint(_ s: CaseStatus) -> Color {
        switch s {
        case .chronic: return .gray.opacity(0.15)
        case .inTreatment: return .blue.opacity(0.15)
        case .review: return .teal.opacity(0.15)
        case .cured: return .green.opacity(0.15)
        }
    }
    private var accessibilitySummary: String {
        "\(item.patientName)，\(item.age)岁\(item.gender)，\(item.relationship)。主诉：\(item.chiefComplaint)。诊断：\(item.diagnosis)。状态：\(item.status.rawValue)。最后更新：\(dateText)。"
    }
}

// MARK: - 小组件

struct AvatarCircle: View {
    let text: String
    let bg: Color
    let fg: Color
    var body: some View {
        ZStack {
            Circle().fill(bg)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(fg)
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }
}

struct StatusPill: View {
    var text: String
    var tint: Color
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(.primary)
    }
}

struct TagCloud: View {
    let items: [String]
    let extraCount: Int
    let tint: Color
    let fg: Color
    var body: some View {
        FlowLayout(spacing: 8, runSpacing: 8) {
            ForEach(items, id: \.self) { s in
                chip(text: s)
            }
            if extraCount > 0 {
                chip(text: "+\(extraCount)")
            }
        }
    }
    private func chip(text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(fg)
    }
}

struct SeverityBadgeCompact: View {
    let severity: Severity
    var body: some View {
        let color: Color = {
            switch severity {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }()
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(severity == .high ? "重" : severity == .medium ? "中" : "轻")
                .font(.caption).foregroundStyle(color)
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(color.opacity(0.1), in: Capsule())
    }
}

struct SeverityStyle {
    let severity: Severity
    var accent: Color {
        switch severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    var cardBG: Color {
        switch severity {
        case .high: return Color.red.opacity(0.06)
        case .medium: return Color.orange.opacity(0.06)
        case .low: return Color.green.opacity(0.06)
        }
    }
    var avatarBG: Color { accent.opacity(0.12) }
    var border: Color { accent.opacity(0.25) }
    var chipBG: Color { accent.opacity(0.12) }
    var chipFG: Color { accent }
    var textStrong: Color { .primary }
    var textSecondary: Color { .secondary }
}

#Preview {
    CaseCard(item: .constant(CaseRepository.samples.first!))
}


