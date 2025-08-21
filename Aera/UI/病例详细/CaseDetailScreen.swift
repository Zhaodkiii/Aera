//
//  CaseDetailScreen.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//



// CaseDetail_Refactored_Unified.swift
// 统一模型 + 单一来源（SSOT）
// - 合并重复类型定义（CDEventKind/CDAttachment/CDEventItem/CDSeverity…）
// - 将“临床严重度”（轻/中/重）与“指标异常度”（正常/偏低/偏高/异常）解耦为两个枚举
// - Palette/Badge/Row 等组件统一依赖新模型，避免命名冲突
// - 尽量保持原 API 风格（日期/时间仍为 String，便于快速落地；可后续切换为 Date）

import SwiftUI

// MARK: - Design Tokens
struct CDDesign {
    static let spacingXS: CGFloat = 6
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let radius: CGFloat = 12
    static let iconDot: CGFloat = 40
    static let accentWidth: CGFloat = 4
}

enum CDTypography {
    static let meta = Font.caption
    static let title = Font.subheadline.weight(.semibold)
    static let body  = Font.callout
}

// MARK: - Models (统一)
/// 临床严重度（轻/中/重），用于事件整体严重程度展示
enum CDClinicalSeverity: String, CaseIterable, Codable, Hashable {
    case 轻度 = "轻度"
    case 中度 = "中度"
    case 重度 = "重度"
}

/// 指标异常度（正常/偏低/偏高/异常），用于测量/检查类结果
enum CDSignalSeverity: String, CaseIterable, Codable, Hashable {
    case 正常 = "正常"
    case 偏低 = "偏低"
    case 偏高 = "偏高"
    case 异常 = "异常"
}

/// 事件类型（合并两套命名）
enum CDEventKind: String, CaseIterable, Codable, Hashable {
    case 测量, 就诊, 检查, 用药, 随访, 文档, 电话, 其他
}

struct CDAttachment: Identifiable, Hashable, Codable {
    let id: UUID = .init()
    var title: String
    /// 优先使用 SF Symbols 名称；若为空，可根据 extHint 推导一个占位图标
    var iconName: String?
    /// 文件扩展名提示（jpg/png/pdf 等），便于后续做预览/图标映射
    var extHint: String?

    var resolvedIcon: String {
        if let iconName, !iconName.isEmpty { return iconName }
        switch (extHint ?? "").lowercased() {
        case "jpg", "jpeg", "png", "gif": return "photo"
        case "pdf": return "doc.text"
        case "doc", "docx": return "doc"
        case "xls", "xlsx": return "tablecells"
        default: return "paperclip"
        }
    }
}

struct CDEventItem: Identifiable, Hashable, Codable {
    var id: UUID = .init()
    var kind: CDEventKind
    var date: String       // yyyy-MM-dd（可后续切 Date）
    var time: String?      // HH:mm
    var title: String
    var detail: String
    var attachments: [CDAttachment] = []
    var author: String?

    // 可选：两类严重度，按需使用其一
    var clinicalSeverity: CDClinicalSeverity?   // 轻/中/重
    var signalSeverity: CDSignalSeverity?       // 正常/偏低/偏高/异常
}

extension CDEventItem {
    static var sampleEvents: [CDEventItem] = [
        // 1) 症状加重（测量/症状类，用“指标”与“临床”双重严重度）
        CDEventItem(
            kind: .测量,
            date: "2024-08-15",
            time: "09:00",
            title: "症状加重",
            detail: "头晕明显，伴随耳鸣，血压 160/95 mmHg。休息后无缓解，服用降压药后好转。",
            attachments: [
                CDAttachment(title: "血压监测图.jpg", iconName: nil, extHint: "jpg")
            ],
            author: "患者自述",
            clinicalSeverity: .中度,
            signalSeverity: .偏高
        ),

        // 2) 复诊记录（随访）
        CDEventItem(
            kind: .随访,
            date: "2024-08-10",
            time: nil,
            title: "复诊记录",
            detail: "门诊复查，血压 140/85 mmHg，较前次有所改善。医嘱：维持原有药物剂量，继续监测血压。",
            attachments: [
                CDAttachment(title: "门诊病历单.pdf", iconName: nil, extHint: "pdf")
            ],
            author: "李医生",
            clinicalSeverity: .轻度,
            signalSeverity: .正常
        ),

        // 3) 实验室检查（检查）
        CDEventItem(
            kind: .检查,
            date: "2024-08-01",
            time: nil,
            title: "实验室检查",
            detail: "血脂、肾功能均正常，血压控制良好。建议继续现有治疗方案。",
            attachments: [
                CDAttachment(title: "检查报告单.jpg", iconName: nil, extHint: "jpg"),
                CDAttachment(title: "血脂检查.pdf", iconName: nil, extHint: "pdf")
            ],
            author: "检验科",
            clinicalSeverity: nil,
            signalSeverity: .正常
        ),

        // 4) 病例文档上传（文档）——新增，覆盖文档类
        CDEventItem(
            kind: .文档,
            date: "2024-07-28",
            time: "14:20",
            title: "上传门诊小结",
            detail: "本次就诊小结已归档，包含血压监测建议与生活方式指导。",
            attachments: [
                CDAttachment(title: "门诊小结.pdf", iconName: "doc.text", extHint: "pdf")
            ],
            author: "导诊台",
            clinicalSeverity: nil,
            signalSeverity: nil
        ),

        // 5) 确诊（就诊）
        CDEventItem(
            kind: .就诊,
            date: "2024-07-20",
            time: nil,
            title: "确诊高血压",
            detail: "诊断依据：多次血压测量均 ≥ 140/90 mmHg，伴有头晕、心悸等症状。",
            attachments: [
                CDAttachment(title: "诊断证明.jpg", iconName: nil, extHint: "jpg")
            ],
            author: "王医生",
            clinicalSeverity: .重度,
            signalSeverity: .异常
        ),

        // 6) 开始用药（用药）
        CDEventItem(
            kind: .用药,
            date: "2024-07-20",
            time: nil,
            title: "开始药物治疗",
            detail: "医嘱：开始口服苯磺酸氨氯地平片 5mg，每日一次，餐后服用。注意监测血压变化。",
            attachments: [],
            author: "王医生",
            clinicalSeverity: .中度,
            signalSeverity: nil
        ),

        // 7) 首次症状（测量/症状）
        CDEventItem(
            kind: .测量,
            date: "2024-07-15",
            time: nil,
            title: "首次症状",
            detail: "出现头痛、心悸，自测血压：150/95 mmHg。无明显诱因，休息后症状持续。",
            attachments: [],
            author: "患者自述",
            clinicalSeverity: .中度,
            signalSeverity: .偏高
        ),

        // 8) 电话随访（电话）——新增，覆盖电话类
        CDEventItem(
            kind: .电话,
            date: "2024-07-16",
            time: "10:30",
            title: "电话随访",
            detail: "患者反馈按时服药，偶发头晕，建议减少久坐、规律复测血压并记录。",
            attachments: [],
            author: "随访护士",
            clinicalSeverity: .轻度,
            signalSeverity: nil
        )
    ]
    // 可按日期降序展示
    .sorted { ($0.date, $0.time ?? "00:00") > ($1.date, $1.time ?? "00:00") }
}

struct CDPatientLite: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let gender: String     // "男" / "女"
    let age: Int
    let mainDx: String
    let riskLabel: String  // 低/中/高风险
    let trendText: String  // 如 “好转中”
    let lastUpdate: String // yyyy-MM-dd
}

extension CDPatientLite {

    static var samplePatient = CDPatientLite(
        id: .init(),
        name: "李小明",
        gender: "男",
        age: 28,
        mainDx: "原发性高血压（轻度）",
        riskLabel: "中风险",
        trendText: "好转中",
        lastUpdate: "2024-08-05"
    )
    
}
// MARK: - Palette
struct CDRowShellPalette {
    var tint: Color
    var border: Color
    var bg: Color
    var iconName: String

    static func by(kind: CDEventKind) -> CDRowShellPalette {
        switch kind {
        case .测量:
            return .init(tint: .orange, border: .orange.opacity(0.25), bg: .orange.opacity(0.08), iconName: "thermometer")
        case .电话:
            return .init(tint: .gray, border: .gray.opacity(0.30), bg: .gray.opacity(0.10), iconName: "phone")
        case .文档:
            return .init(tint: .blue, border: .blue.opacity(0.25), bg: .blue.opacity(0.07), iconName: "doc.text")
        case .用药:
            return .init(tint: .green, border: .green.opacity(0.25), bg: .green.opacity(0.07), iconName: "pills")
        case .就诊:
            return .init(tint: .red, border: .red.opacity(0.25), bg: .red.opacity(0.07), iconName: "stethoscope")
        case .随访:
            return .init(tint: .teal, border: .teal.opacity(0.25), bg: .teal.opacity(0.07), iconName: "message")
        case .检查:
            return .init(tint: .blue, border: .blue.opacity(0.25), bg: .blue.opacity(0.08), iconName: "waveform.path.ecg")
        case .其他:
            return .init(tint: .purple, border: .purple.opacity(0.25), bg: .purple.opacity(0.07), iconName: "circle.dashed")
        }
    }
}

// MARK: - Badges
struct CDChipPalette {
    var bg: Color
    var fg: Color
    var border: Color

    static func clinical(_ s: CDClinicalSeverity) -> CDChipPalette {
        switch s {
        case .轻度: return .init(bg: .yellow.opacity(0.20), fg: .yellow.darker(), border: .yellow.opacity(0.35))
        case .中度: return .init(bg: .orange.opacity(0.20), fg: .orange.darker(), border: .orange.opacity(0.35))
        case .重度: return .init(bg: .red.opacity(0.20),    fg: .red.darker(),    border: .red.opacity(0.35))
        }
    }

    static func signal(_ s: CDSignalSeverity) -> CDChipPalette {
        switch s {
        case .正常: return .init(bg: .green.opacity(0.18),  fg: .green.darker(),  border: .green.opacity(0.35))
        case .偏低: return .init(bg: .orange.opacity(0.18), fg: .orange.darker(), border: .orange.opacity(0.35))
        case .偏高: return .init(bg: .orange.opacity(0.18), fg: .orange.darker(), border: .orange.opacity(0.35))
        case .异常: return .init(bg: .red.opacity(0.18),    fg: .red.darker(),    border: .red.opacity(0.35))
        }
    }
}

struct CDBadgeCapsule: View {
    var text: String
    var palette: CDChipPalette
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(palette.bg)
                    .overlay(Capsule().stroke(palette.border, lineWidth: 1))
            )
            .foregroundStyle(palette.fg)
    }
}

// MARK: - Attachment pill
struct CDAttachPill: View {
    var file: CDAttachment

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: file.resolvedIcon).font(.caption)
            Text(file.title).lineLimit(1)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.08))
                .overlay(Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1))
        )
        .foregroundStyle(Color.blue)
    }
}

// MARK: - Row
struct CDTimelineRow: View {
    let item: CDEventItem

    var body: some View {
        let shell = CDRowShellPalette.by(kind: item.kind)

        HStack(alignment: .top, spacing: CDDesign.spacingMD) {
            // 左侧圆点 + 图标（40×40）
            ZStack {
                Circle().fill(shell.tint)
                Image(systemName: shell.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: CDDesign.iconDot, height: CDDesign.iconDot)
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
            .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
            VStack{
                // 顶部：日期/时间 + 严重度（优先展示临床严重度；无则展示指标异常度）
                HStack(alignment: .firstTextBaseline, spacing: CDDesign.spacingSM) {
                    HStack(spacing: CDDesign.spacingXS) {
                        Image(systemName: "calendar").font(.caption2).foregroundStyle(.secondary)
                        Text(item.date)
                        if let t = item.time, !t.isEmpty {
                            Image(systemName: "clock").font(.caption2).foregroundStyle(.secondary)
                                .padding(.leading, CDDesign.spacingXS)
                            Text(t)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    if let s = item.clinicalSeverity {
                        CDBadgeCapsule(text: s.rawValue, palette: .clinical(s)).fixedSize()
                    } else if let a = item.signalSeverity {
                        CDBadgeCapsule(text: a.rawValue, palette: .signal(a)).fixedSize()
                    }
                }
                // 右侧内容卡片
                VStack(alignment: .leading, spacing: CDDesign.spacingSM) {


                    // 标题
                    HStack(spacing: CDDesign.spacingSM) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                        Button { /* TODO: edit */ } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.gray)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }

                    // 正文
                    Text(item.detail)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    // 附件
                    if !item.attachments.isEmpty {
                        HStack(spacing: CDDesign.spacingXS) {
                            Image(systemName: "paperclip").font(.caption2)
                            Text("附件").font(.caption)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: CDDesign.spacingSM) {
                                ForEach(item.attachments) { f in
                                    CDAttachPill(file: f)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // 记录人
                    if let a = item.author, !a.isEmpty {
                        Divider().padding(.top, 2)
                        Text("记录人：\(a)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(CDDesign.spacingMD)
                .background(
                    RoundedRectangle(cornerRadius: CDDesign.radius)
                        .stroke(shell.border, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: CDDesign.radius).fill(Color.white)
                        )
                        .overlay(
                            // 左侧强调色条
                            RoundedRectangle(cornerRadius: CDDesign.radius)
                                .stroke(shell.tint, lineWidth: CDDesign.accentWidth)
                                .mask(
                                    RoundedRectangle(cornerRadius: CDDesign.radius)
                                        .stroke(lineWidth: CDDesign.accentWidth)
                                        .padding(.leading, -200)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                )
                                .opacity(0.9)
                        )
                )
            }

        }
        .overlay(alignment: .leading) {
            let centerX = CDDesign.iconDot / 2
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
                .offset(x: centerX)
                .padding(.top, CDDesign.iconDot + CDDesign.spacingMD)
        }
        .padding(.horizontal, CDDesign.spacingLG)
        .contentShape(Rectangle())
    }
}

// MARK: - Header Card / Tag Toggle / Screen
struct CDTagToggle: View {
    let label: String
    let isPrimary: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(isPrimary ? Color.accentColor : Color(.systemBackground))
                .foregroundStyle(isPrimary ? Color.white : Color.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isPrimary ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct CDPatientHeaderCard: View {
    let p: CDPatientLite

    var body: some View {
        VStack(spacing: 0) {
//            HStack {
//                Image(systemName: "chevron.left").font(.headline)
//                Spacer()
//                Text("病例详情").font(.headline)
//                Spacer()
//                Color.clear.frame(width: 24)
//            }
//            .padding(.horizontal, 16).padding(.vertical, 10)
//            .background(Color.white)
//            Divider()

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(Color.green.opacity(0.15))
                    Text(String(p.name.prefix(1)))
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(p.name).font(.title3).fontWeight(.semibold)
                        CDBadgeCapsule(text: p.gender, palette: .init(bg: .secondary.opacity(0.08), fg: .secondary, border: .secondary.opacity(0.25)))
                    }
                    HStack(spacing: 8) {
                        Label("\(p.age)岁", systemImage: "person")
                            .labelStyle(.titleAndIcon).font(.caption).foregroundStyle(.secondary)
                        Text(p.mainDx).font(.callout)
                    }
                    HStack(spacing: 8) {
                        let riskPal: CDChipPalette = {
                            switch p.riskLabel {
                            case "低风险": return .init(bg: .green.opacity(0.12), fg: .green, border: .green.opacity(0.35))
                            case "中风险": return .init(bg: .orange.opacity(0.12), fg: .orange, border: .orange.opacity(0.35))
                            case "高风险": return .init(bg: .red.opacity(0.12), fg: .red, border: .red.opacity(0.35))
                            default: return .init(bg: .primary.opacity(0.06), fg: .secondary, border: .primary.opacity(0.15))
                            }
                        }()
                        CDBadgeCapsule(text: p.riskLabel, palette: riskPal)
                        Label(p.trendText, systemImage: "arrow.down.right")
                            .font(.caption).foregroundStyle(.green)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.caption2).foregroundStyle(.secondary)
                        Text("最近更新：\(p.lastUpdate)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.25), lineWidth: 1))
                    .padding(.horizontal, 16)
            )
            .padding(.vertical, 8)
        }
        .background(Color.white)
    }
}

struct CaseDetailScreen: View {
    let patient: CDPatientLite
    @State private var selectedKind: CDEventKind? = nil
    let events: [CDEventItem]

    private var filtered: [CDEventItem] {
        guard let k = selectedKind else { return events }
        return events.filter { $0.kind == k }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    CDPatientHeaderCard(p: patient)

                    // 筛选标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CDTagToggle(label: "全部", isPrimary: selectedKind == nil) { selectedKind = nil }
                            ForEach(CDEventKind.allCases, id: \.self) { k in
                                CDTagToggle(label: k.rawValue, isPrimary: selectedKind == k) { selectedKind = k }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // 时间线列表
                    VStack(spacing: 12) {
                        ForEach(filtered) { ev in
                            CDTimelineRow(item: ev)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }

            // 悬浮新增按钮
            NavigationLink {/* TODO: 新增记录 */
                // 新增记录 action
                CDNewRecordScreen()
            } label: {
                HStack(spacing: 8) { Image(systemName: "plus"); Text("新增记录") }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue))
                    .foregroundStyle(.white)
                    .shadow(radius: 4, y: 2)
            }
            .padding(.trailing, 20).padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Helpers
private extension Color {
    func darker(_ amount: Double = 0.35) -> Color {
        let dark = Color.black.opacity(amount)
        return Color(uiColor: UIColor(self).withAlphaComponent(1.0)).overlay(with: dark)
    }
}

private extension Color {
    func overlay(with top: Color) -> Color {
        let base = UIColor(self)
        let over = UIColor(top)
        var rb: CGFloat = 0, gb: CGFloat = 0, bb: CGFloat = 0, ab: CGFloat = 0
        var ro: CGFloat = 0, go: CGFloat = 0, bo: CGFloat = 0, ao: CGFloat = 0
        base.getRed(&rb, green: &gb, blue: &bb, alpha: &ab)
        over.getRed(&ro, green: &go, blue: &bo, alpha: &ao)
        let a = ao + ab * (1 - ao)
        guard a > 0 else { return Color.clear }
        let r = (ro * ao + rb * ab * (1 - ao)) / a
        let g = (go * ao + gb * ab * (1 - ao)) / a
        let b = (bo * ao + bb * ab * (1 - ao)) / a
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}
// MARK: - 预览 & 示例数据
// MARK: - 预览 & 示例数据
struct CaseDetailScreen_Previews: PreviewProvider {
//
//    static var samplePatient = CDPatientLite(
//        id: .init(),
//        name: "李小明",
//        gender: "男",
//        age: 28,
//        mainDx: "原发性高血压（轻度）",
//        riskLabel: "中风险",
//        trendText: "好转中",
//        lastUpdate: "2024-08-05"
//    )



    static var previews: some View {
        NavigationView {
            CaseDetailScreen(patient: .samplePatient, events: CDEventItem.sampleEvents)
        }
    }
}

import SwiftUI







//
//// MARK: - Design Tokens
//struct CDDesign {
//    static let spacingXS: CGFloat = 6
//    static let spacingSM: CGFloat = 8
//    static let spacingMD: CGFloat = 12
//    static let spacingLG: CGFloat = 16
//    static let radius: CGFloat = 12
//    static let iconDot: CGFloat = 40
//    static let accentWidth: CGFloat = 4
//}
//
//// MARK: - Models
//enum CDSeverity: String, CaseIterable {
//    case 轻度 = "轻度"
//    case 中度 = "中度"
//    case 重度 = "重度"
//}
//
//enum CDEventKind: String, CaseIterable {
//    case 高血压, 随访, 文档, 测量, 用药, 电话, 其他
//}
//
//struct CDAttachment: Identifiable, Hashable {
//    let id = UUID()
//    var title: String
//    var icon: String = "doc.text"
//}
//
//struct CDEventItem: Identifiable {
//    let id = UUID()
//    var kind: CDEventKind
//    var date: String
//    var time: String?
//    var severity: CDSeverity?
//    var title: String
//    var detail: String
//    var attachments: [CDAttachment] = []
//    var author: String?
//}
//
//// MARK: - Palette
//struct CDRowShellPalette {
//    var tint: Color
//    var border: Color
//    var bg: Color
//    var iconName: String
//
//    static func by(kind: CDEventKind) -> CDRowShellPalette {
//        switch kind {
//        case .测量:
//            return .init(tint: .orange, border: .orange.opacity(0.25), bg: Color.orange.opacity(0.08), iconName: "thermometer")
//        case .电话:
//            return .init(tint: .gray, border: .gray.opacity(0.3), bg: Color.gray.opacity(0.08), iconName: "phone")
//        case .文档:
//            return .init(tint: .blue, border: .blue.opacity(0.25), bg: Color.blue.opacity(0.07), iconName: "doc.text")
//        case .用药:
//            return .init(tint: .green, border: .green.opacity(0.25), bg: Color.green.opacity(0.07), iconName: "pills")
//        case .高血压:
//            return .init(tint: .red, border: .red.opacity(0.25), bg: Color.red.opacity(0.07), iconName: "stethoscope")
//        case .随访:
//            return .init(tint: .teal, border: .teal.opacity(0.25), bg: Color.teal.opacity(0.07), iconName: "message")
//        case .其他:
//            return .init(tint: .purple, border: .purple.opacity(0.25), bg: Color.purple.opacity(0.07), iconName: "circle.dashed")
//        }
//    }
//}
//
//// MARK: - Badge
//struct CDBadgeCapsule: View {
//    var text: String
//    var bg: Color
//    var fg: Color
//    var border: Color
//
//    init(text: String, palette: BadgePalette) {
//        self.text = text
//        self.bg = palette.bg
//        self.fg = palette.fg
//        self.border = palette.border
//    }
//
//    struct BadgePalette {
//        var bg: Color
//        var fg: Color
//        var border: Color
//
//        static func severity(_ s: CDSeverity) -> BadgePalette {
//            switch s {
//            case .轻度:
//                return .init(bg: Color.yellow.opacity(0.2), fg: .yellow.darker(), border: .yellow.opacity(0.35))
//            case .中度:
//                return .init(bg: Color.orange.opacity(0.2), fg: .orange.darker(), border: .orange.opacity(0.35))
//            case .重度:
//                return .init(bg: Color.red.opacity(0.2), fg: .red.darker(), border: .red.opacity(0.35))
//            }
//        }
//    }
//
//    var body: some View {
//        Text(text)
//            .font(.caption)
//            .padding(.horizontal, 8)
//            .padding(.vertical, 4)
//            .background(
//                Capsule()
//                    .fill(bg)
//                    .overlay(Capsule().stroke(border, lineWidth: 1))
//            )
//            .foregroundStyle(fg)
//    }
//}
//
//// MARK: - Attachment pill
//struct CDAttachPill: View {
//    var file: CDAttachment
//
//    var body: some View {
//        HStack(spacing: 6) {
//            Image(systemName: file.icon).font(.caption)
//            Text(file.title).lineLimit(1)
//        }
//        .font(.caption)
//        .padding(.horizontal, 10)
//        .padding(.vertical, 6)
//        .background(
//            Capsule()
//                .fill(Color.blue.opacity(0.08))
//                .overlay(Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1))
//        )
//        .foregroundStyle(Color.blue)
//    }
//}
//
//// MARK: - Row
//struct CDTimelineRow: View {
//    let item: CDEventItem
//
//    var body: some View {
//        let shell = CDRowShellPalette.by(kind: item.kind)
//
//        HStack(alignment: .top, spacing: CDDesign.spacingMD) {
//
//            // 左侧圆点 + 图标（40×40）
//            ZStack {
//                Circle().fill(shell.tint)
//                Image(systemName: shell.iconName)
//                    .font(.system(size: 20, weight: .semibold))
//                    .foregroundStyle(.white)
//            }
//            .frame(width: CDDesign.iconDot, height: CDDesign.iconDot)
//            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
//            .overlay(
//                Circle().stroke(.white.opacity(0.8), lineWidth: 2)
//            )
//
//            // 右侧内容卡片
//            VStack(alignment: .leading, spacing: CDDesign.spacingSM) {
//
//                // 顶部：日期/时间 + 严重度
//                HStack(alignment: .firstTextBaseline, spacing: CDDesign.spacingSM) {
//                    HStack(spacing: CDDesign.spacingXS) {
//                        Image(systemName: "calendar")
//                            .font(.caption2).foregroundStyle(.secondary)
//                        Text(item.date)
//
//                        if let t = item.time, !t.isEmpty {
//                            Image(systemName: "clock")
//                                .font(.caption2).foregroundStyle(.secondary)
//                                .padding(.leading, CDDesign.spacingXS)
//                            Text(t)
//                        }
//                    }
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//
//                    Spacer(minLength: 0)
//
//                    if let s = item.severity {
//                        CDBadgeCapsule(text: s.rawValue, palette: .severity(s))
//                            .fixedSize()
//                    }
//                }
//
//                // 标题 + 编辑
//                HStack(spacing: CDDesign.spacingSM) {
//                    Text(item.title)
//                        .font(.subheadline.weight(.semibold))
//                        .foregroundStyle(.primary)
//
//                    Spacer(minLength: 0)
//
//                    Button {
//                        // TODO: edit action
//                    } label: {
//                        Image(systemName: "square.and.pencil")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundStyle(.gray)
//                            .padding(6)
//                    }
//                    .buttonStyle(.plain)
//                }
//
//                // 正文
//                Text(item.detail)
//                    .font(.callout)
//                    .foregroundStyle(.primary)
//                    .fixedSize(horizontal: false, vertical: true)
//
//                // 附件
//                if !item.attachments.isEmpty {
//                    HStack(spacing: CDDesign.spacingXS) {
//                        Image(systemName: "paperclip").font(.caption2)
//                        Text("附件").font(.caption)
//                        Spacer(minLength: 0)
//                    }
//                    .foregroundStyle(.secondary)
//                    .padding(.top, 2)
//
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: CDDesign.spacingSM) {
//                            ForEach(item.attachments) { f in
//                                CDAttachPill(file: f)
//                            }
//                        }
//                        .padding(.vertical, 2)
//                    }
//                }
//
//                // 记录人
//                if let a = item.author, !a.isEmpty {
//                    Divider().padding(.top, 2)
//                    Text("记录人：\(a)")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//            }
//            .padding(CDDesign.spacingMD)
//            .background(
//                // 卡片底色 + 1px 边框
//                RoundedRectangle(cornerRadius: CDDesign.radius)
//                    .stroke(shell.border, lineWidth: 1)
//                    .background(
//                        RoundedRectangle(cornerRadius: CDDesign.radius)
//                            .fill(Color.white)
//                    )
//                    // 左侧强调色条（与 TimelineItemView 相同思路）
//                    .overlay(
//                        RoundedRectangle(cornerRadius: CDDesign.radius)
//                            .stroke(shell.tint, lineWidth: CDDesign.accentWidth)
//                            .mask(
//                                RoundedRectangle(cornerRadius: CDDesign.radius)
//                                    .stroke(lineWidth: CDDesign.accentWidth)
//                                    .padding(.leading, -200) // 只保留左边
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            )
//                            .opacity(0.9)
//                    )
//            )
//        }
//        .overlay(alignment: .leading) {
//            // 竖向时间轴连接线（与圆点中心对齐）
//            let centerX = CDDesign.iconDot / 2
//            Rectangle()
//                .fill(Color.gray.opacity(0.2))
//                .frame(width: 1)
//                .offset(x: centerX)
//                .padding(.top, CDDesign.iconDot + CDDesign.spacingMD)
//        }
//        .padding(.horizontal, CDDesign.spacingLG)
//        .contentShape(Rectangle())
//    }
//}
//
//// MARK: - Helpers
//private extension Color {
//    func darker(_ amount: Double = 0.35) -> Color {
//        // 简单“变暗”效果：降低不透明度叠加黑
//        let dark = Color.black.opacity(amount)
//        return Color(uiColor:
//            UIColor(self).withAlphaComponent(1.0)
//        ).overlay(with: dark)
//    }
//}
//
//private extension Color {
//    func overlay(with top: Color) -> Color {
//        // 轻量合成（避免引入额外依赖）
//        let base = UIColor(self)
//        let over = UIColor(top)
//        var rb: CGFloat = 0, gb: CGFloat = 0, bb: CGFloat = 0, ab: CGFloat = 0
//        var ro: CGFloat = 0, go: CGFloat = 0, bo: CGFloat = 0, ao: CGFloat = 0
//        base.getRed(&rb, green: &gb, blue: &bb, alpha: &ab)
//        over.getRed(&ro, green: &go, blue: &bo, alpha: &ao)
//        let a = ao + ab * (1 - ao)
//        guard a > 0 else { return Color.clear }
//        let r = (ro * ao + rb * ab * (1 - ao)) / a
//        let g = (go * ao + gb * ab * (1 - ao)) / a
//        let b = (bo * ao + bb * ab * (1 - ao)) / a
//        return Color(red: r, green: g, blue: b, opacity: a)
//    }
//}
//
//// MARK: - Preview
//struct CDTimelineRow_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                CDTimelineRow(item:
//                    .init(kind: .测量,
//                          date: "2024-08-15",
//                          time: "09:00",
//                          severity: .轻度,
//                          title: "头晕加重",
//                          detail: "今晨起床后头晕，血压 160/95 mmHg，已服降压药后缓解。",
//                          attachments: [.init(title: "🖼️ 血压拍照.jpg")],
//                          author: "家属"))
//                CDTimelineRow(item:
//                    .init(kind: .电话,
//                          date: "2024-08-10",
//                          time: nil,
//                          severity: nil,
//                          title: "电话随访记录",
//                          detail: "患者自述血压 140/85 mmHg，较前有所改善。",
//                          attachments: [.init(title: "📄 随访问卷.pdf", icon: "doc.richtext")],
//                          author: "李医生"))
//                CDTimelineRow(item:
//                    .init(kind: .文档,
//                          date: "2024-08-01",
//                          time: nil,
//                          severity: nil,
//                          title: "实验室检查",
//                          detail: "血脂、肝肾功能基本正常，血压控制尚可。",
//                          attachments: [.init(title: "🖼️ 检查回执.jpg"),
//                                        .init(title: "📄 报告单.pdf", icon: "doc.text")],
//                          author: "检验科"))
//                CDTimelineRow(item:
//                    .init(kind: .用药,
//                          date: "2024-07-20",
//                          time: nil,
//                          severity: nil,
//                          title: "开启药物治疗",
//                          detail: "硝苯地平缓释片 5mg，每日一次，晚饭后服用。",
//                          attachments: [],
//                          author: "门诊"))
//                CDTimelineRow(item:
//                    .init(kind: .高血压,
//                          date: "2024-07-20",
//                          time: nil,
//                          severity: .重度,
//                          title: "就诊：高血压",
//                          detail: "多次血压≥140/90 mmHg，伴头晕心悸。",
//                          attachments: [.init(title: "🖼️ 体征照片.jpg")],
//                          author: "内科"))
//            }
//            .padding(.vertical, 24)
//        }
//        .background(Color(white: 0.98))
//    }
//}
//





////
//// MARK: - Design Tokens
//private enum CDMetrics {
//    static let cornerRadius: CGFloat = 12
//    static let cardPadding: CGFloat = 16
//    static let hGap: CGFloat = 12
//    static let vGap: CGFloat = 8
//    static let avatarSize: CGFloat = 40
//    static let strokeWidth: CGFloat = 1
//}
//
//private enum CDTypography {
//    static let meta = Font.caption    // 日期/时间/标签 等
//    static let title = Font.subheadline.weight(.semibold)
//    static let body  = Font.callout
//}
//
////// MARK: - Row
////struct CDTimelineRow: View {
////    let item: CDEventItem
////
////    var body: some View {
////        let shell = CDRowShellPalette.by(kind: item.kind)
////
////        HStack(alignment: .top, spacing: CDMetrics.hGap) {
////            // 左侧圆形图标
////            ZStack {
////                Circle()
////                    .fill(shell.tint)
////                    .opacity(0.95)
////                Image(systemName: shell.iconName)
////                    .font(.system(size: 18, weight: .semibold))
////                    .foregroundStyle(.white)
////            }
////            .frame(width: CDMetrics.avatarSize, height: CDMetrics.avatarSize)
////            .accessibilityHidden(true)
////
////            // 右侧内容
////            VStack(alignment: .leading, spacing: CDMetrics.vGap) {
////                Header(item: item)
////
////                TitleAndDetail(item: item)
////
////                if !item.attachments.isEmpty {
////                    AttachmentsSection(attachments: item.attachments)
////                }
////
////                if let a = item.author, !a.isEmpty {
////                    Divider()
////                        .padding(.top, 2)
////                    Text("记录人：\(a)")
////                        .font(CDTypography.meta)
////                        .foregroundStyle(.secondary)
////                        .accessibilityLabel("记录人 \(a)")
////                }
////            }
////        }
////        .padding(CDMetrics.cardPadding)
////        .background(
////            RoundedRectangle(cornerRadius: CDMetrics.cornerRadius)
////                .fill(shell.bg)
////                .overlay(
////                    RoundedRectangle(cornerRadius: CDMetrics.cornerRadius)
////                        .stroke(shell.border, lineWidth: CDMetrics.strokeWidth)
////                )
////        )
////        .contentShape(Rectangle())
////        .accessibilityElement(children: .combine)
////    }
////}
//
////struct CDDesign {
////    static let spacingXS: CGFloat = 6
////    static let spacingSM: CGFloat = 8
////    static let spacingMD: CGFloat = 12
////    static let spacingLG: CGFloat = 16
////    static let radius: CGFloat = 12
////    static let iconDot: CGFloat = 40
////    static let accentWidth: CGFloat = 4
////}
////
////struct CDTimelineRow: View {
////    let item: CDEventItem
////
////    var body: some View {
////        let shell = CDRowShellPalette.by(kind: item.kind)
////
////        HStack(alignment: .top, spacing: CDDesign.spacingMD) {
////            // 圆点 + 图标（40×40）
////            ZStack {
////                Circle().fill(shell.tint).opacity(0.95)
////                Image(systemName: shell.iconName)
////                    .font(.system(size: 20, weight: .regular))
////                    .foregroundStyle(.white)
////            }
////            .frame(width: CDDesign.iconDot, height: CDDesign.iconDot)
////            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
////
////            // 右侧内容
////            VStack(alignment: .leading, spacing: CDDesign.spacingSM) {
////
////                // 顶部信息：日期/时间 + 严重度/状态
////                HStack(alignment: .firstTextBaseline) {
////                    HStack(spacing: CDDesign.spacingXS) {
////                        Image(systemName: "calendar")
////                            .font(.caption2).foregroundStyle(.secondary)
////                        Text(item.date)
////
////                        if let t = item.time, !t.isEmpty {
////                            Image(systemName: "clock")
////                                .font(.caption2).foregroundStyle(.secondary)
////                                .padding(.leading, CDDesign.spacingXS)
////                            Text(t)
////                        }
////                    }
////                    .font(.caption).foregroundStyle(.secondary)
////
////                    Spacer(minLength: 0)
////
////                    if let s = item.severity {
////                        CDBadgeCapsule(text: s.rawValue, palette: .severity(s))
////                            .fixedSize()
////                    }
////                }
////
////                // 标题
////                HStack(spacing: CDDesign.spacingSM) {
////                    Text(item.title)
////                        .font(.subheadline)
////                        .fontWeight(.semibold)
////                        .foregroundStyle(.primary)
////                    Spacer(minLength: 0)
////                }
////
////                // 正文
////                Text(item.detail)
////                    .font(.callout)
////                    .foregroundStyle(.primary)
////                    .fixedSize(horizontal: false, vertical: true)
////
////                // 附件（可横滑）
////                if !item.attachments.isEmpty {
////                    HStack(spacing: CDDesign.spacingXS) {
////                        Image(systemName: "paperclip")
////                            .font(.caption2).foregroundStyle(.secondary)
////                        Text("附件")
////                            .font(.caption).foregroundStyle(.secondary)
////                        Spacer(minLength: 0)
////                    }
////                    .padding(.top, 2)
////
////                    ScrollView(.horizontal, showsIndicators: false) {
////                        HStack(spacing: CDDesign.spacingSM) {
////                            ForEach(item.attachments) { f in
////                                CDAttachPill(file: f)
////                            }
////                        }
////                        .padding(.vertical, 2)
////                    }
////                }
////
////                // 记录人
////                if let a = item.author, !a.isEmpty {
////                    Divider().padding(.top, 2)
////                    Text("记录人：\(a)")
////                        .font(.caption)
////                        .foregroundStyle(.secondary)
////                }
////            }
////        }
////        .padding(CDDesign.spacingMD)
////        .background(
////            RoundedRectangle(cornerRadius: CDDesign.radius)
////                .fill(shell.bg)
////                .overlay(
////                    // 1px 边框
////                    RoundedRectangle(cornerRadius: CDDesign.radius)
////                        .stroke(shell.border, lineWidth: 1)
////                )
////                .overlay(alignment: .leading) {
////                    // 左侧强调色条 4px
////                    RoundedRectangle(cornerRadius: max(CDDesign.radius - 2, 0))
////                        .fill(shell.tint)
////                        .frame(width: CDDesign.accentWidth)
////                }
////        )
////        .overlay(alignment: .leading) {
////            // 时间轴竖线（连接下一个 item），与圆点中心对齐
////            GeometryReader { geo in
////                let centerX = CDDesign.iconDot / 2
////                Rectangle()
////                    .fill(Color.gray.opacity(0.2))
////                    .frame(width: 1)
////                    .offset(x: centerX)
////                    .padding(.top, CDDesign.iconDot + CDDesign.spacingMD)
////            }
////        }
////        .contentShape(Rectangle())
////    }
////}
//// MARK: - Subviews
//
//private struct Header: View {
//    let item: CDEventItem
//
//    var body: some View {
//        HStack(alignment: .firstTextBaseline) {
//            // 日期 + 时间（与全局一致的 meta 样式）
//            HStack(spacing: 6) {
//                Label {
//                    HStack(spacing: 6) {
//                        Text(item.date)
//                        if let t = item.time, !t.isEmpty {
//                            Text(t)
//                        }
//                    }
//                } icon: {
//                    Image(systemName: "calendar")
//                }
//                .labelStyle(.iconOnly)
//                .font(.caption2)
//                .foregroundStyle(.secondary)
//
//                // 为了与视觉稿一致：额外显示时钟图标仅在有时间时出现
//                if let t = item.time, !t.isEmpty {
//                    Image(systemName: "clock")
//                        .font(.caption2)
//                        .foregroundStyle(.secondary)
//                        .accessibilityHidden(true)
//                }
//            }
//            .font(CDTypography.meta)
//            .foregroundStyle(.secondary)
//
//            Spacer(minLength: 0)
//
//            // 严重度徽章（与全局 Badge 风格保持一致）
//            if let s = item.severity {
//                CDBadgeCapsule(text: s.rawValue, palette: .severity(s))
//                    .fixedSize() // 避免被压缩
//            }
//        }
//    }
//}
//
//private struct TitleAndDetail: View {
//    let item: CDEventItem
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            HStack {
//                Text(item.title)
//                    .font(CDTypography.title)
//                    .lineLimit(2)
//                    .accessibilityAddTraits(.isHeader)
//                Spacer(minLength: 0)
//            }
//
//            Text(item.detail)
//                .font(CDTypography.body)
//                .foregroundStyle(.primary)
//                .fixedSize(horizontal: false, vertical: true)
//        }
//    }
//}
//
//private struct AttachmentsSection: View {
//    let attachments: [CDAttachment]
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack(spacing: 6) {
//                Image(systemName: "paperclip")
//                    .font(.caption2)
//                    .foregroundStyle(.secondary)
//                    .accessibilityHidden(true)
//                Text("附件")
//                    .font(CDTypography.meta)
//                    .foregroundStyle(.secondary)
//                Spacer(minLength: 0)
//            }
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 8) {
//                    ForEach(attachments) { f in
//                        CDAttachPill(file: f)
//                    }
//                }
//                .padding(.vertical, 2) // 与整体行距统一的小缓冲
//            }
//        }
//        .padding(.top, 2)
//    }
//}
//
//// MARK: - 数据模型（Case Detail 专用命名）
//struct CDPatientLite: Identifiable, Hashable {
//    let id: UUID
//    let name: String
//    let gender: String     // "男"/"女"
//    let age: Int
//    let mainDx: String     // 主诊断/主诉/病名
//    let riskLabel: String  // 低/中/高风险 等
//    let trendText: String  // 趋势文案：如 “好转中”
//    let lastUpdate: String // yyyy-MM-dd
//}
//
//enum CDEventKind: String, Codable, CaseIterable, Hashable {
//    case measurement = "测量"
//    case visit = "就诊"
//    case exam = "检查"
//    case medication = "用药"
//    case followup = "随访"
//}
//
//struct CDEventItem: Identifiable, Hashable {
//    let id: UUID = .init()
//    let kind: CDEventKind
//    let date: String       // yyyy-MM-dd
//    let time: String?      // HH:mm 可空
//    let title: String
//    let detail: String     // 富文本可后续替换 AttributedString
//    let author: String?    // 记录人
//    let attachments: [CDAttachment]
//    let severity: CDSeverity? // 某些事件可带“偏高/偏低/异常”等
//}
//
//struct CDAttachment: Identifiable, Hashable {
//    let id: UUID = .init()
//    let filename: String
//    let extHint: String   // "jpg" / "pdf" / "png" ...
//}
//
//enum CDSeverity: String {
//    case normal = "正常"
//    case mildLow = "偏低"
//    case mildHigh = "偏高"
//    case abnormal = "异常"
//}
//
//// MARK: - 颜色/样式（独立命名，不与历史冲突）
//struct CDChipPalette {
//    let fg: Color; let bg: Color; let border: Color
//    static func risk(_ level: String) -> CDChipPalette {
//        switch level {
//        case "低风险": return .init(fg: .green,  bg: .green.opacity(0.12),  border: .green.opacity(0.35))
//        case "中风险": return .init(fg: .orange, bg: .orange.opacity(0.12), border: .orange.opacity(0.35))
//        case "高风险": return .init(fg: .red,    bg: .red.opacity(0.12),    border: .red.opacity(0.35))
//        default:       return .init(fg: .secondary, bg: .primary.opacity(0.06), border: .primary.opacity(0.15))
//        }
//    }
//    static func severity(_ s: CDSeverity?) -> CDChipPalette {
//        guard let s else { return .init(fg: .secondary, bg: .primary.opacity(0.06), border: .primary.opacity(0.15)) }
//        switch s {
//        case .normal:   return .init(fg: .green,  bg: .green.opacity(0.12),  border: .green.opacity(0.35))
//        case .mildLow:  return .init(fg: .orange, bg: .orange.opacity(0.12), border: .orange.opacity(0.35))
//        case .mildHigh: return .init(fg: .orange, bg: .orange.opacity(0.12), border: .orange.opacity(0.35))
//        case .abnormal: return .init(fg: .red,    bg: .red.opacity(0.12),    border: .red.opacity(0.35))
//        }
//    }
//}
//
//struct CDRowShellPalette {
//    let bg: Color; let border: Color; let iconName: String; let tint: Color
//    static func by(kind: CDEventKind) -> CDRowShellPalette {
//        switch kind {
//        case .measurement: return .init(bg: .orange.opacity(0.08), border: .orange.opacity(0.35), iconName: "thermometer", tint: .orange)
//        case .visit:       return .init(bg: .red.opacity(0.08),    border: .red.opacity(0.35),    iconName: "stethoscope", tint: .red)
//        case .exam:        return .init(bg: .blue.opacity(0.08),   border: .blue.opacity(0.35),   iconName: "doc.text",     tint: .blue)
//        case .medication:  return .init(bg: .green.opacity(0.08),  border: .green.opacity(0.35),  iconName: "pills",        tint: .green)
//        case .followup:    return .init(bg: .gray.opacity(0.10),   border: .gray.opacity(0.30),   iconName: "phone",        tint: .gray)
//        }
//    }
//}
//
//// MARK: - 微组件
//struct CDBadgeCapsule: View {
//    let text: String
//    let palette: CDChipPalette
//    var body: some View {
//        Text(text)
//            .font(.caption)
//            .padding(.horizontal, 8).padding(.vertical, 4)
//            .background(RoundedRectangle(cornerRadius: 8).fill(palette.bg))
//            .overlay(RoundedRectangle(cornerRadius: 8).stroke(palette.border, lineWidth: 1))
//            .foregroundStyle(palette.fg)
//    }
//}
//
//struct CDAttachPill: View {
//    let file: CDAttachment
//    var body: some View {
//        HStack(spacing: 6) {
//            Image(systemName: "paperclip")
//            Text(file.filename).lineLimit(1)
//        }
//        .font(.caption)
//        .padding(.horizontal, 8).padding(.vertical, 6)
//        .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.06)))
//        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.25), lineWidth: 1))
//        .foregroundStyle(.blue)
//    }
//}
//
//struct CDTagToggle: View {
//    let label: String
//    let isPrimary: Bool
//    let action: () -> Void
//    var body: some View {
//        Button(action: action) {
//            Text(label)
//                .font(.caption)
//                .padding(.horizontal, 10).padding(.vertical, 6)
//                .background(isPrimary ? Color.accentColor : Color(.systemBackground))
//                .foregroundStyle(isPrimary ? Color.white : Color.primary)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(isPrimary ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 1)
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// MARK: - 时间线行
////struct CDTimelineRow: View {
////    let item: CDEventItem
////    var body: some View {
////        let shell = CDRowShellPalette.by(kind: item.kind)
////        HStack(alignment: .top, spacing: 12) {
////            ZStack {
////                Circle().fill(shell.tint).opacity(0.95)
////                Image(systemName: shell.iconName).foregroundStyle(.white)
////            }
////            .frame(width: 40, height: 40)
////            VStack(alignment: .leading, spacing: 8) {
////                // 顶部信息
////                HStack(alignment: .firstTextBaseline) {
////                    HStack(spacing: 6) {
////                        Image(systemName: "calendar")
////                            .font(.caption2).foregroundStyle(.secondary)
////                        Text(item.date)
////                        if let t = item.time, !t.isEmpty {
////                            Image(systemName: "clock").font(.caption2).foregroundStyle(.secondary)
////                            Text(t)
////                        }
////                    }
////                    .font(.caption).foregroundStyle(.secondary)
////                    Spacer()
////                    // 严重度或状态徽章
////                    if let s = item.severity {
////                        CDBadgeCapsule(text: s.rawValue, palette: .severity(s))
////                    }
////                }
////                // 标题 & 内容
////                HStack {
////                    Text(item.title).font(.subheadline).fontWeight(.semibold)
////                    Spacer()
////                }
////                Text(item.detail)
////                    .font(.callout)
////                    .foregroundStyle(.primary)
////                    .fixedSize(horizontal: false, vertical: true)
////
////                // 附件
////                if !item.attachments.isEmpty {
////                    HStack(spacing: 6) {
////                        Image(systemName: "paperclip").font(.caption2).foregroundStyle(.secondary)
////                        Text("附件").font(.caption).foregroundStyle(.secondary)
////                        Spacer(minLength: 0)
////                    }
////                    .padding(.top, 2)
////
////                    ScrollView(.horizontal, showsIndicators: false) {
////                        HStack(spacing: 8) {
////                            ForEach(item.attachments) { f in
////                                CDAttachPill(file: f)
////                            }
////                        }
////                    }
////                }
////
////                // 记录人
////                if let a = item.author, !a.isEmpty {
////                    Divider().padding(.top, 2)
////                    Text("记录人：\(a)")
////                        .font(.caption)
////                        .foregroundStyle(.secondary)
////                }
////            }
////        }
////        .padding(12)
////        .background(
////            RoundedRectangle(cornerRadius: 12)
////                .fill(shell.bg)
////                .overlay(
////                    RoundedRectangle(cornerRadius: 12)
////                        .stroke(shell.border, lineWidth: 1)
////                )
////        )
////    }
////}
//
//// MARK: - 头部卡片
//struct CDPatientHeaderCard: View {
//    let p: CDPatientLite
//    @State private var showBack = false // 仅占位演示
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // 顶部栏
//            HStack {
//                Button {
//                    showBack.toggle()
//                } label: {
//                    Image(systemName: "chevron.left")
//                        .font(.headline)
//                }
//                .buttonStyle(.plain)
//
//                Spacer()
//                Text("病例详情").font(.headline)
//                Spacer()
//                Color.clear.frame(width: 24) // 对称占位
//            }
//            .padding(.horizontal, 16).padding(.vertical, 10)
//            .background(Color.white)
//            Divider()
//
//            // 患者卡
//            HStack(alignment: .top, spacing: 12) {
//                ZStack {
//                    Circle().fill(Color.green.opacity(0.15))
//                    Text(String(p.name.prefix(1)))
//                        .font(.title3).fontWeight(.semibold)
//                        .foregroundStyle(.green)
//                }
//                .frame(width: 52, height: 52)
//
//                VStack(alignment: .leading, spacing: 8) {
//                    HStack(spacing: 8) {
//                        Text(p.name).font(.title3).fontWeight(.semibold)
//                        CDBadgeCapsule(text: p.gender, palette: .init(fg: .secondary, bg: .secondary.opacity(0.08), border: .secondary.opacity(0.25)))
//                    }
//                    HStack(spacing: 8) {
//                        Label("\(p.age)岁", systemImage: "person")
//                            .labelStyle(.titleAndIcon).font(.caption).foregroundStyle(.secondary)
//                        Text(p.mainDx).font(.callout)
//                    }
//                    HStack(spacing: 8) {
//                        CDBadgeCapsule(text: p.riskLabel, palette: .risk(p.riskLabel))
//                        Label(p.trendText, systemImage: "arrow.down.right")
//                            .font(.caption).foregroundStyle(.green)
//                    }
//                    HStack(spacing: 6) {
//                        Image(systemName: "calendar").font(.caption2).foregroundStyle(.secondary)
//                        Text("最近更新：\(p.lastUpdate)")
//                            .font(.caption).foregroundStyle(.secondary)
//                    }
//                }
//                Spacer()
//            }
//            .padding(16)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color.green.opacity(0.06))
//                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.25), lineWidth: 1))
//                    .padding(.horizontal, 16)
//            )
//            .padding(.vertical, 8)
//        }
//        .background(Color.white)
//    }
//}
//
//// MARK: - 主页面
//struct CaseDetailScreen: View {
//    let patient: CDPatientLite
//    @State private var selectedKind: CDEventKind? = nil
//    let events: [CDEventItem]
//
//    // 过滤
//    private var filtered: [CDEventItem] {
//        guard let k = selectedKind else { return events }
//        return events.filter { $0.kind == k }
//    }
//
//    var body: some View {
//        ZStack(alignment: .bottomTrailing) {
//            ScrollView {
//                VStack(spacing: 16) {
//                    CDPatientHeaderCard(p: patient)
//
//                    // 筛选标签
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 8) {
//                            CDTagToggle(label: "全部", isPrimary: selectedKind == nil) {
//                                selectedKind = nil
//                            }
//                            ForEach(CDEventKind.allCases, id: \.self) { k in
//                                CDTagToggle(label: k.rawValue, isPrimary: selectedKind == k) {
//                                    selectedKind = k
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 16)
//                    }
//
//                    // 时间线列表
//                    VStack(spacing: 12) {
//                        ForEach(filtered) { ev in
//                            CDTimelineRow(item: ev)
//                            
//                                .padding(.horizontal, 16)
//                        }
//                    }
//                    .padding(.bottom, 60) // 给悬浮按钮留空间
//                }
//            }
//
//            // 悬浮新增按钮
//            Button {
//                // TODO: 跳转到新增记录页
//            } label: {
//                HStack(spacing: 8) {
//                    Image(systemName: "plus")
//                    Text("新增记录")
//                }
//                .padding(.horizontal, 16).padding(.vertical, 12)
//                .background(Capsule().fill(Color.blue))
//                .foregroundStyle(.white)
//                .shadow(radius: 4, y: 2)
//            }
//            .padding(.trailing, 20).padding(.bottom, 28)
//        }
//        .background(Color(.systemGroupedBackground))
//        .navigationBarHidden(true)
//    }
//}
//
//// MARK: - 预览 & 示例数据
//struct CaseDetailScreen_Previews: PreviewProvider {
//    static var samplePatient = CDPatientLite(
//        id: .init(),
//        name: "李小明",
//        gender: "男",
//        age: 28,
//        mainDx: "原发性高血压（轻度）",
//        riskLabel: "中风险",
//        trendText: "好转中",
//        lastUpdate: "2024-08-05"
//    )
//
//    static var sampleEvents: [CDEventItem] = [
//        .init(
//            kind: .measurement,
//            date: "2024-08-15", time: "09:00",
//            title: "血压偏高",
//            detail: "晨起测量，收缩压 160/95 mmHg。近期偶有头晕，建议继续监测。",
//            author: "张护士",
//            attachments: [ .init(filename: "📎 血压计读数.jpg", extHint: "jpg") ],
//            severity: .mildHigh
//        ),
//        .init(
//            kind: .followup,
//            date: "2024-08-10", time: nil,
//            title: "电话随访记录",
//            detail: "复述用药情况，血压 140/85 mmHg，较前有所改善。嘱其坚持原有方案。",
//            author: "李医生",
//            attachments: [ .init(filename: "📎 随访问卷.pdf", extHint: "pdf") ],
//            severity: nil
//        ),
//        .init(
//            kind: .exam,
//            date: "2024-08-01", time: nil,
//            title: "实验室检查",
//            detail: "肝肾功能均正常，血压控制良好。建议继续治疗方案。",
//            author: "检验科",
//            attachments: [
//                .init(filename: "📎 报告单.jpg", extHint: "jpg"),
//                .init(filename: "📎 检查报告.pdf", extHint: "pdf")
//            ],
//            severity: nil
//        ),
//        .init(
//            kind: .visit,
//            date: "2024-07-20", time: nil,
//            title: "门诊高血压",
//            detail: "多次血压≥140/90 mmHg，伴头晕、心悸等症状。",
//            author: "王医生",
//            attachments: [ .init(filename: "📎 就诊票据.jpg", extHint: "jpg") ],
//            severity: .abnormal
//        ),
//        .init(
//            kind: .medication,
//            date: "2024-07-20", time: nil,
//            title: "开始用药：氨氯地平 5mg qd",
//            detail: "晚间服用，注意记录血压变化。",
//            author: "王医生",
//            attachments: [],
//            severity: nil
//        ),
//        .init(
//            kind: .measurement,
//            date: "2024-07-15", time: nil,
//            title: "居家首次测量",
//            detail: "主诉头晕、心悸，血压 150/95 mmHg。无诱因。",
//            author: nil,
//            attachments: [],
//            severity: .mildHigh
//        )
//    ]
//
//    static var previews: some View {
//        NavigationView {
//            CaseDetailScreen(patient: samplePatient, events: sampleEvents)
//        }
//    }
//}
