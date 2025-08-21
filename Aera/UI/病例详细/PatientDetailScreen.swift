//
//  PatientDetailScreen.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI
import SwiftUI

// MARK: - Theme

struct AppTheme {
    static let bg = Color(.systemBackground)
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let border = Color.black.opacity(0.1)

    // Brand / semantic
    static let primary = Color(red: 0.02, green: 0.01, blue: 0.07)         // #030213
    static let accent  = Color(red: 0.91, green: 0.92, blue: 0.94)         // #e9ebef
    static let ring    = Color(hue: 0.58, saturation: 0.07, brightness: 0.88)

    static let green50  = Color(red: 240/255, green: 244/255, blue: 251/255) // 近似
    static let green200 = Color(red: 187/255, green: 230/255, blue: 195/255)
    static let green600 = Color(red: 0.16, green: 0.59, blue: 0.38)

    static let yellow100 = Color(red: 1.0, green: 0.96, blue: 0.75)
    static let yellow800 = Color(red: 0.59, green: 0.47, blue: 0.05)

    static let orange   = Color(hue: 0.09, saturation: 0.85, brightness: 0.90)
    static let orangeBg = Color(hue: 0.09, saturation: 0.25, brightness: 1.0)

    static let blue     = Color(hue: 0.58, saturation: 0.5, brightness: 0.9)
    static let blueBg   = Color(hue: 0.58, saturation: 0.18, brightness: 0.97)

    static let red      = Color(red: 0.83, green: 0.10, blue: 0.24)         // #d4183d
    static let redBg    = Color(red: 1.0, green: 0.92, blue: 0.93)

    static let grayBg   = Color(.secondarySystemBackground)
}

// MARK: - Models

enum RecordKind: String, CaseIterable, Identifiable {
    case all = "全部"
    case level1 = "1级"
    case revisit = "复诊"
    case exam = "体检"
    case meds = "用药"
    case followup = "随访"

    var id: String { rawValue }
}

enum EntryType {
    case fever          // thermometer (orange)
    case phone          // phone (gray)
    case exam           // file-text (blue)
    case revisit        // stethoscope (red)
    case medication     // pill (green)

    var iconName: String {
        switch self {
        case .fever: return "thermometer"
        case .phone: return "phone"
        case .exam: return "doc.text"
        case .revisit: return "stethoscope"
        case .medication: return "pills"
        }
    }

    var tint: Color {
        switch self {
        case .fever: return AppTheme.orange
        case .phone: return .gray
        case .exam: return AppTheme.blue
        case .revisit: return AppTheme.red
        case .medication: return AppTheme.green600
        }
    }

    var badgeText: String {
        switch self {
        case .fever: return "1级"
        case .phone: return "随访"
        case .exam: return "体检"
        case .revisit: return "复诊"
        case .medication: return "用药"
        }
    }

    var badgeStyle: (bg: Color, fg: Color) {
        switch self {
        case .fever: return (AppTheme.orangeBg, Color.orange.darken())
        case .phone: return (AppTheme.grayBg, .primary)
        case .exam: return (AppTheme.blueBg, AppTheme.blue)
        case .revisit: return (AppTheme.redBg, AppTheme.red)
        case .medication: return (AppTheme.green50, AppTheme.green600)
        }
    }
}

struct Attachment: Identifiable {
    let id = UUID()
    var title: String
    var icon: String = "paperclip"
}

struct TimelineEntry: Identifiable {
    let id = UUID()
    var date: String        // e.g., "2024-08-15"
    var time: String?       // optional (only some items show time)
    var type: EntryType
    var title: String
    var body: String
    var attachments: [Attachment] = []
    var recorder: String?   // 记录人
}

struct Patient {
    var name: String
    var genderAge: String    // "28岁 · 女"
    var tag: String          // "社区"
    var chief: String        // 主诉/工单
    var riskBadge: String    // "高风险中"
    var riskTrendText: String // "近7天下降"
    var lastUpdate: String    // "2024-08-05"
}

// MARK: - Sample Data

let demoPatient = Patient(
    name: "张小丽",
    genderAge: "28岁 · 女",
    tag: "社区",
    chief: "高血压 复发 伴位置信息 头痛（近一周）",
    riskBadge: "高风险中",
    riskTrendText: "近7天下降",
    lastUpdate: "2024-08-05"
)

let demoEntries: [TimelineEntry] = [
    .init(
        date: "2024-08-15",
        time: "09:00",
        type: .fever,
        title: "1级紧急",
        body: "发热加重，伴随头晕，血压 160/95 mmHg。患者目前无过敏史，服用降压药后有下降。",
        attachments: [Attachment(title: "🖼️ 血压仪读数.jpg")],
        recorder: "患者自述"
    ),
    .init(
        date: "2024-08-10",
        time: nil,
        type: .phone,
        title: "电话随访记录",
        body: "复查建议，血压 140/85 mmHg，较前有所改善。建议：坚持原有药物方案，继续监测血压。",
        attachments: [Attachment(title: "🖼️ 随访外呼.pdf")],
        recorder: "李医生"
    ),
    .init(
        date: "2024-08-01",
        time: nil,
        type: .exam,
        title: "实验室体检",
        body: "血常规、肝肾功能均在正常，血压控制良好。建议继续保持监测及治疗方案。",
        attachments: [
            Attachment(title: "🖼️ 体检回执单.jpg"),
            Attachment(title: "🖼️ 血常规体检.pdf"),
        ],
        recorder: "体检科室"
    ),
    .init(
        date: "2024-07-20",
        time: nil,
        type: .revisit,
        title: "复诊高血压",
        body: "就诊要点：多次血压测量 ≥ 140/90 mmHg，并有头晕、心悸等症状。",
        attachments: [Attachment(title: "🖼️ 就诊票据.jpg")],
        recorder: "王医生"
    ),
    .init(
        date: "2024-07-20",
        time: nil,
        type: .medication,
        title: "开具药物治疗",
        body: "药嘱：口服缬沙坦氢氯噻嗪 5mg，每日一次，饭后服用。注意监测血压变化。",
        attachments: [],
        recorder: "王医生"
    ),
    .init(
        date: "2024-07-15",
        time: nil,
        type: .fever,
        title: "首次发热",
        body: "出现发热、心悸等，自测血压：150/95 mmHg。无明确诱因，建议后续持续观察。",
        attachments: [],
        recorder: nil
    ),
]

// MARK: - Views

struct Chip: View {
    var text: String
    var bg: Color = AppTheme.accent
    var fg: Color = .primary
    var border: Color = AppTheme.border

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(bg))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(border))
            .foregroundStyle(fg)
    }
}

struct AvatarCircleaa: View {
    var initials: String
    var size: CGFloat = 64
    var body: some View {
        ZStack {
            Circle().fill(AppTheme.green50)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(AppTheme.green600)
        }
        .frame(width: size, height: size)
    }
}

struct HeaderBar: View {
    var title: String
    var onBack: (() -> Void)?

    var body: some View {
        HStack {
            Button(action: { onBack?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)
            Spacer()
            Text(title).font(.system(size: 18, weight: .semibold))
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }
}

struct PatientCard: View {
    var p: Patient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AvatarCircleaa(initials: "张小")
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("张小丽")
                            .font(.system(size: 20, weight: .semibold))
                        Chip(text: p.tag)
                            .font(.system(size: 12))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(p.genderAge)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Text(p.chief)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    HStack(spacing: 8) {
                        Chip(
                            text: p.riskBadge,
                            bg: AppTheme.yellow100,
                            fg: AppTheme.yellow800,
                            border: AppTheme.yellow100.opacity(0.6)
                        )
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                            Text(p.riskTrendText)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.green600)
                    }
                }
            }

            HStack(spacing: 8) {
                Text("工单：").foregroundStyle(AppTheme.textSecondary)
                Text("反复发热持续 2周")
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }.font(.system(size: 14))

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("最近更新：\(p.lastUpdate)")
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.system(size: 12))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.green200)
                )
                .overlay(
                    Rectangle()
                        .fill(AppTheme.green200)
                        .frame(width: 4)
                        .cornerRadius(2),
                    alignment: .leading
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

struct FilterRow: View {
    @Binding var selected: RecordKind
    var kinds: [RecordKind] = RecordKind.allCases

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(AppTheme.textSecondary)
                ForEach(kinds) { k in
                    Button {
                        selected = k
                    } label: {
                        if k == .all {
                            Text(k.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(AppTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text(k.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border))
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
    }
}

struct TimelineItemView: View {
    var entry: TimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Icon bubble
            ZStack {
                Circle().fill(entry.type.tint.opacity(0.15))
                Image(systemName: entry.type.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(radius: 0, y: 0)
            }
            .overlay(
                Circle().stroke(entry.type.tint.opacity(0.2))
            )
            .background(Circle().fill(entry.type.tint))
            .frame(width: 48, height: 48)
            .mask(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(entry.date)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textSecondary)
                        if let t = entry.time {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(t)
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    Chip(
                        text: entry.type.badgeText,
                        bg: entry.type.badgeStyle.bg,
                        fg: entry.type.badgeStyle.fg,
                        border: entry.type.badgeStyle.bg.opacity(0.7)
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Button {
                            // edit action
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.gray)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(entry.body)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !entry.attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "paperclip")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Text("附件")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 2)

                            FlexibleChips(items: entry.attachments.map { $0.title })
                        }
                    }

                    if let rec = entry.recorder {
                        Divider().padding(.top, 4)
                        Text("记录人：\(rec)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.border, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(entry.type.tint, lineWidth: 4)
                                .mask(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(lineWidth: 4)
                                        .padding(.leading, -200) // left border only
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                )
                                .opacity(0.9)
                        )
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

struct FlexibleChips: View {
    var items: [String]

    var body: some View {
        // Simple wrap using LazyVGrid w/ adaptive columns
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { t in
                Chip(text: t, bg: AppTheme.blueBg, fg: AppTheme.blue, border: AppTheme.blueBg)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Root

struct PatientDetailScreen: View {
    @State private var selected: RecordKind = .all
    @State private var entries: [TimelineEntry] = demoEntries

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 12) {
                    PatientCard(p: demoPatient)

                    // Filters
                    FilterRow(selected: $selected)

                    // Timeline (with subtle axis)
                    VStack(spacing: 20) {
                        ForEach(entries.indices, id: \.self) { idx in
                            VStack(spacing: 0) {
                                TimelineItemView(entry: entries[idx])
                                    .overlay(alignment: .leading) {
                                        if idx < entries.count - 1 {
                                            // Vertical connector
                                            Rectangle()
                                                .fill(AppTheme.border)
                                                .frame(width: 1)
                                                .padding(.top, 70)
                                                .padding(.leading, 24) // align with icon center
                                                .padding(.bottom, -20)
                                        }
                                    }
                            }
                            .padding(.top, idx == 0 ? 4 : 0)
                        }
                    }
                    .padding(.bottom, 80)

                    // Submit button
                    Button {
                        // 提交 action
                    } label: {
                        Text("提交")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.border)
                                    .fill(Color.white)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .background(AppTheme.bg)
            .overlay(alignment: .top) {
                HeaderBar(title: "健康档案")
                    .ignoresSafeArea(edges: .top)
            }

            // Floating add button
            Button {
                // 新增记录 action
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("新增记录")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.vertical, 12).padding(.horizontal, 16)
                .background(Capsule().fill(AppTheme.blue))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 90)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Helpers

extension Color {
    func darken(_ amount: CGFloat = 0.5) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return self }
        return Color(hue: h, saturation: s, brightness: max(0, b - amount))
    }
}

// MARK: - Preview

struct PatientDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientDetailScreen()
        }
        .environment(\.colorScheme, .light)

        NavigationView {
            PatientDetailScreen()
        }
        .environment(\.colorScheme, .dark)
    }
}
