//
//  MVNotificationCenter.swift
//  Aera
//
//  Created by 話 on 2025/8/22.
//

import Foundation
import UserNotifications


/// 服用方式/补充说明（可多选）
struct MVMethod: OptionSet, Codable {
    let rawValue: Int
    static let warmWater   = MVMethod(rawValue: 1 << 0) // 温水送服
    static let chew        = MVMethod(rawValue: 1 << 1) // 嚼服
    static let dissolve    = MVMethod(rawValue: 1 << 2) // 含服
    static let external    = MVMethod(rawValue: 1 << 3) // 外用
    static let asDirected  = MVMethod(rawValue: 1 << 4) // 遵医嘱
}

/// 人群作息 Archetype（起床/三餐/就寝）
// 让餐点时间也可 Hash
struct MVMealTime: Equatable, Hashable, Codable {
    let hour: Int
    let minute: Int
}
/// 人群作息 Archetype（起床/三餐/就寝）
struct MVArchetype: Equatable, Hashable, Codable, Identifiable {
    var id: String { name }
    let name: String
    let wakeHour: Int
    let meals: [MVMealTime] // 早餐/午餐/晚餐
    /// 允许 >=24 表示次日小时（例如 25 == 次日01:00）
    let bedtimeHour: Int

    static let standardAdult = MVArchetype(name: "标准成人", wakeHour: 7, meals: [.init(hour:8,minute:0), .init(hour:12,minute:30), .init(hour:19,minute:0)], bedtimeHour: 23)
    static let earlyBird     = MVArchetype(name: "早睡早起", wakeHour: 5, meals: [.init(hour:7,minute:0), .init(hour:12,minute:0), .init(hour:18,minute:0)], bedtimeHour: 22)
    static let nightOwl      = MVArchetype(name: "晚睡晚起", wakeHour: 9, meals: [.init(hour:10,minute:0), .init(hour:13,minute:30), .init(hour:20,minute:0)], bedtimeHour: 25 /* 次日1点 */)
    static let elderly       = MVArchetype(name: "老年作息", wakeHour: 6, meals: [.init(hour:7,minute:30), .init(hour:11,minute:30), .init(hour:18,minute:0)], bedtimeHour: 22)
}

/// 用药规则
struct MVDosingRule: Codable {
    var frequency: MVFrequency = .daily(timesPerDay: 1)
    var durationDays: Int = 7
    var timing: MVTiming = .none
    var methods: MVMethod = []
    var customNote: String = ""
    var strictInterval: Bool = false // 严格间隔：夜间不回避
    var startAnchor: Date = Date()   // 起始时间锚点（首剂或期望开始）
}

/// 单次提醒槽位
struct MVDoseSlot: Identifiable, Hashable, Codable {
    let id: UUID
    var planned: Date
    var editable: Bool = true
    var reason: String = ""
}

/// 完整用药计划
struct MVDosingPlan: Identifiable, Codable {
    var id = UUID()
    var rule: MVDosingRule
    var archetype: MVArchetype
    var quiet: MVQuietWindow = MVQuietWindow(start: 23, end: 7)   // ✅
    var schedule: [MVDoseSlot] = []
}

// MARK: - Planner (Generator)

enum MVPlanner {

    /// 生成完整计划（含多天）
    static func generate(rule: MVDosingRule,
                         archetype: MVArchetype,
                         quiet: MVQuietWindow = MVQuietWindow(start: 23, end: 7),
                         calendar: Calendar = .current) -> MVDosingPlan {
        var plan = MVDosingPlan(rule: rule, archetype: archetype, quiet: quiet, schedule: [])
        switch rule.frequency {
        case .daily(let times):
            for d in 0..<rule.durationDays {
                let base = calendar.startOfDay(for: rule.startAnchor).addingTimeInterval(TimeInterval(86400 * d))
                let daySlots = dailySlots(times: times, base: base, rule: rule, archetype: archetype, quiet: quiet, calendar: calendar)
                plan.schedule.append(contentsOf: daySlots)
            }
        case .everyXHours(let h):
            let totalHours = rule.durationDays * 24
            var current = rule.startAnchor
            var slots: [MVDoseSlot] = []
            while calendar.dateComponents([.hour], from: rule.startAnchor, to: current).hour ?? 0 <= totalHours {
                let adjusted = adjustForQuiet(current, strict: rule.strictInterval, quiet: quiet, calendar: calendar)
                let reason = rule.strictInterval && adjusted != current ? "严格间隔：夜间仍按时" : "q\(h)h 间隔"
                slots.append(MVDoseSlot(id: UUID(), planned: adjusted, reason: reason))
                guard let next = calendar.date(byAdding: .hour, value: h, to: current) else { break }
                current = next
            }
            plan.schedule = slots
        case .everyNDays(let n, let times):
            for d in stride(from: 0, to: rule.durationDays, by: n) {
                let base = calendar.startOfDay(for: rule.startAnchor).addingTimeInterval(TimeInterval(86400 * d))
                let daySlots = dailySlots(times: times, base: base, rule: rule, archetype: archetype, quiet: quiet, calendar: calendar)
                plan.schedule.append(contentsOf: daySlots)
            }
        }

        plan.schedule.sort { $0.planned < $1.planned }
        return plan
    }

    /// 每日定次：依据 timing + 作息生成当天的 N 次

    private static func dailySlots(times: Int, base: Date, rule: MVDosingRule,
                                   archetype: MVArchetype, quiet: MVQuietWindow,
                                   calendar: Calendar) -> [MVDoseSlot]  {
        var results: [MVDoseSlot] = []
        let anchors = dayAnchors(base: base, archetype: archetype, calendar: calendar)

        func slot(at comps: DateComponents, reason: String) -> MVDoseSlot? {
            guard let t = calendar.date(bySettingHour: comps.hour ?? 8, minute: comps.minute ?? 0, second: 0, of: base) else { return nil }
            let adjusted = adjustForQuiet(t, strict: rule.strictInterval, quiet: quiet, calendar: calendar)
            return MVDoseSlot(id: UUID(), planned: adjusted, reason: reason)
        }

        switch rule.timing {
        case .beforeMeal:
            let mealOffsets = [(-30, "早餐前30m"), (-30, "午餐前30m"), (-30, "晚餐前30m")]
            for i in 0..<min(times, anchors.meals.count) {
                let m = anchors.meals[i]
                let offset = mealOffsets[i].0
                if let planned = calendar.date(byAdding: .minute, value: offset, to: m) {
                    let comps = calendar.dateComponents([.hour,.minute], from: planned).dateComponentsOnlyHM()
                    if let s = slot(at: comps, reason: mealOffsets[i].1) { results.append(s) }
                }
            }
        case .afterMeal:
            let mealOffsets = [(30, "早餐后30m"), (30, "午餐后30m"), (30, "晚餐后30m")]
            for i in 0..<min(times, anchors.meals.count) {
                let m = anchors.meals[i]
                let offset = mealOffsets[i].0
                if let planned = calendar.date(byAdding: .minute, value: offset, to: m) {
                    let comps = calendar.dateComponents([.hour,.minute], from: planned).dateComponentsOnlyHM()
                    if let s = slot(at: comps, reason: mealOffsets[i].1) { results.append(s) }
                }
            }
        case .withMeal:
            let labels = ["早餐随餐","午餐随餐","晚餐随餐"]
            for i in 0..<min(times, anchors.meals.count) {
                let m = anchors.meals[i]
                let comps = calendar.dateComponents([.hour,.minute], from: m).dateComponentsOnlyHM()
                if let s = slot(at: comps, reason: labels[i]) { results.append(s) }
            }
        case .morning:
            if let s = slot(at: DateComponents(hour: anchors.wakeHour+0, minute: 15), reason: "晨起15m") { results.append(s) }
            results.append(contentsOf: evenlyDistributed(times: max(times-1,0), between: anchors.wakeHour+2, and: anchors.bedtimeHour-2, base: base, quiet: quiet, strict: rule.strictInterval, calendar: calendar))
        case .bedtime:
            if let s = slot(at: DateComponents(hour: anchors.bedtimeHour-1, minute: 0), reason: "睡前60m") { results.append(s) }
            results.append(contentsOf: evenlyDistributed(times: max(times-1,0), between: anchors.wakeHour+1, and: anchors.bedtimeHour-3, base: base, quiet: quiet, strict: rule.strictInterval, calendar: calendar))
        case .fasting:
            // 空腹：餐前≥1h 或 餐后≥2h —— 选醒窗三等分并远离餐时
            results.append(contentsOf: fastingDistributed(times: times, anchors: anchors, base: base, quiet: quiet, strict: rule.strictInterval, calendar: calendar))
        case .none:
            // 无特殊：按醒窗等分
            results.append(contentsOf: evenlyDistributed(times: times, between: anchors.wakeHour+1, and: anchors.bedtimeHour-1, base: base, quiet: quiet, strict: rule.strictInterval, calendar: calendar))
        }

        // times 若大于已放置数量，补齐为等分
        if results.count < times {
            let remain = times - results.count
            results.append(contentsOf: evenlyDistributed(times: remain, between: anchors.wakeHour+1, and: anchors.bedtimeHour-1, base: base, quiet: quiet, strict: rule.strictInterval, calendar: calendar))
        }

        return results.sorted { $0.planned < $1.planned }
    }

    private static func fastingDistributed(times: Int, anchors: (wakeHour:Int, meals:[Date], bedtimeHour:Int), base: Date, quiet: MVQuietWindow, strict: Bool, calendar: Calendar) -> [MVDoseSlot] {
        // 选取远离餐后的时间点：早餐后2h、午餐后2.5h、晚餐后2.5h
        let offsets: [Double] = [2.0, 2.5, 2.5]
        var slots: [MVDoseSlot] = []
        for i in 0..<min(times, anchors.meals.count) {
            let m = anchors.meals[i]
            guard let t = calendar.date(byAdding: .minute, value: Int(offsets[i]*60), to: m) else { continue }
            let adjusted = adjustForQuiet(t, strict: strict, quiet: quiet, calendar: calendar)
            let s = MVDoseSlot(id: UUID(), planned: adjusted, reason: "空腹：远离第\(i+1)餐")
            slots.append(s)
        }
        if slots.count < times {
            // 余下按醒窗等分
            let remain = times - slots.count
            slots.append(contentsOf: evenlyDistributed(times: remain, between: anchors.wakeHour+1, and: anchors.bedtimeHour-2, base: base, quiet: quiet, strict: strict, calendar: calendar))
        }
        return slots
    }

    private static func evenlyDistributed(times: Int, between startHour: Int, and endHour: Int, base: Date, quiet: MVQuietWindow, strict: Bool, calendar: Calendar) -> [MVDoseSlot] {
        guard times > 0 else { return [] }
        let span = max(endHour - startHour, 1)
        var results: [MVDoseSlot] = []
        for i in 0..<times {
            let frac = Double(i + 1) / Double(times + 1)
            let hour = startHour + Int(round(frac * Double(span)))
            let comps = DateComponents(hour: hour, minute: (i % 2) * 30)
            if let t = calendar.date(bySettingHour: comps.hour ?? startHour, minute: comps.minute ?? 0, second: 0, of: base) {
                let adjusted = adjustForQuiet(t, strict: strict, quiet: quiet, calendar: calendar)
                let s = MVDoseSlot(id: UUID(), planned: adjusted, reason: "等分醒窗")
                results.append(s)
            }
        }
        return results
    }

    private static func dayAnchors(base: Date, archetype: MVArchetype, calendar: Calendar) -> (wakeHour:Int, meals:[Date], bedtimeHour:Int) {
        let wakeH = archetype.wakeHour
        let bedtimeH = archetype.bedtimeHour % 24 // 25 代表次日1点
        var meals: [Date] = []
        for m in archetype.meals {
            if let d = calendar.date(bySettingHour: m.hour, minute: m.minute, second: 0, of: base) {
                meals.append(d)
            }
        }
        return (wakeH, meals, bedtimeH)
        
    }
    private static func adjustForQuiet(_ date: Date, strict: Bool, quiet: MVQuietWindow, calendar: Calendar) -> Date {
        guard !strict else { return date }
        let hour = calendar.component(.hour, from: date)
        guard quiet.contains(hour: hour) else { return date }

        // 将时间推进到静默窗口结束后的最近半小时刻度
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = quiet.end
        comps.minute = 0
        var target = calendar.date(from: comps) ?? date
        if target < date { target = calendar.date(byAdding: .day, value: 1, to: target) ?? target }

        let minute = calendar.component(.minute, from: target)
        let roundedMinute = (minute < 15) ? 0 : (minute < 45 ? 30 : 0)
        comps = calendar.dateComponents([.year, .month, .day], from: target)
        comps.hour = calendar.component(.hour, from: target)
        comps.minute = roundedMinute
        return calendar.date(from: comps) ?? target
    }
}

    /// 若处于夜间回避时段，则根据策略调整
//private func adjustForQuiet(_ date: Date, strict: Bool, quiet: ClosedRange<Int>, calendar: Calendar) -> Date {
//        guard !strict else { return date }
//        let h = calendar.component(.hour, from: date)
//        let inQuiet: Bool = {
//            if quiet.lowerBound <= quiet.upperBound { // 正常区间（不跨午夜）
//                return (quiet.lowerBound...quiet.upperBound).contains(h)
//            } else { // 跨午夜，如 23...7
//                return h >= quiet.lowerBound || h <= quiet.upperBound
//            }
//        }()
//        guard inQuiet else { return date }
//        // 调整到 quiet.upperBound 后的最近半小时刻度
//        var comps = calendar.dateComponents([.year,.month,.day], from: date)
//        comps.hour = quiet.upperBound
//        comps.minute = 0
//        var target = calendar.date(from: comps) ?? date
//        if target < date { target = calendar.date(byAdding: .day, value: 1, to: target) ?? target }
//        // 对齐到最近的 00/30
//        let minute = calendar.component(.minute, from: target)
//        let rounded = minute < 15 ? 0 : (minute < 45 ? 30 : 0)
//        comps = calendar.dateComponents([.year,.month,.day], from: target)
//        comps.hour = calendar.component(.hour, from: target)
//        comps.minute = rounded
//        return calendar.date(from: comps) ?? target
//    }

//func adjustForQuiet(_ date: Date, strict: Bool, quiet: MVQuietWindow, calendar: Calendar) -> Date {
//    guard !strict else { return date }
//    let hour = calendar.component(.hour, from: date)
//    guard quiet.contains(hour: hour) else { return date }
//
//    // 将时间推进到静默窗口结束后的最近半小时刻度
//    var comps = calendar.dateComponents([.year, .month, .day], from: date)
//    comps.hour = quiet.end
//    comps.minute = 0
//    var target = calendar.date(from: comps) ?? date
//    if target < date { target = calendar.date(byAdding: .day, value: 1, to: target) ?? target }
//
//    let minute = calendar.component(.minute, from: target)
//    let roundedMinute = (minute < 15) ? 0 : (minute < 45 ? 30 : 0)
//    comps = calendar.dateComponents([.year, .month, .day], from: target)
//    comps.hour = calendar.component(.hour, from: target)
//    comps.minute = roundedMinute
//    return calendar.date(from: comps) ?? target
//}
private extension DateComponents {
    func dateComponentsOnlyHM() -> DateComponents { DateComponents(hour: self.hour, minute: self.minute) }
}

// MARK: - Notification Scheduling (Local)

final class MVNotificationCenter {
    static let shared = MVNotificationCenter()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert,.sound,.badge])
    }

    func schedule(plan: MVDosingPlan, title: String = "用药提醒", body: String = "请按时服药") async {
        // 由于 iOS 限制单应用最多挂起 ~64 个通知，这里只调度最近的 60 个，剩余建议按天滚动补齐。
        let upcoming = plan.schedule.filter { $0.planned > Date() }.prefix(60)
        for slot in upcoming {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body + (slot.reason.isEmpty ? "" : "（\(slot.reason)）")
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: slot.planned)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(identifier: slot.id.uuidString, content: content, trigger: trigger)
            try? await center.add(req)
        }
    }

    func cancel(plan: MVDosingPlan) async {
        let ids = plan.schedule.map { $0.id.uuidString }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
