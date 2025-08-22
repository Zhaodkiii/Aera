//
//  DosingPlannerView.swift
//  Aera
//
//  Created by 話 on 2025/8/22.
//

// MedVaultDosingPlanner.swift
// 病例夹 · 智能用药方案与提醒 · Swift 数据模型 + SwiftUI 页面（可直接落地）
// 说明：集成模型、调度器、SwiftUI 交互页与本地通知。仅依赖 SwiftUI / Foundation / UserNotifications。
import SwiftUI
import UserNotifications

// MARK: - Core Models

/// 用药频率模式
enum MVFrequency: Equatable, Codable {
    case daily(timesPerDay: Int)           // 每日定次（QD/BID/TID/QID...）
    case everyXHours(Int)                  // 每 X 小时（q8h/q12h...）
    case everyNDays(Int, timesPerDay: Int) // 每 N 天，定次（可留作扩展）
}

/// 用药时间说明（与餐/睡/空腹等的关系）
enum MVTiming: String, CaseIterable, Identifiable, Codable {
    case none = "无特殊"
    case beforeMeal = "饭前"
    case afterMeal = "饭后"
    case withMeal = "随餐"
    case fasting = "空腹"
    case morning = "晨起"
    case bedtime = "睡前"
    var id: String { rawValue }
}

/// 夜间回避窗口，允许跨午夜（例如 23→7）
struct MVQuietWindow: Equatable, Codable {
    var start: Int  // 0...23
    var end: Int    // 0...23

    func contains(hour h: Int) -> Bool {
        if start <= end {
            return (start...end).contains(h)
        } else {
            // 跨午夜：23→7 等价于 [23,23] ∪ [0,7]
            return h >= start || h <= end
        }
    }
}

// MARK: - SwiftUI View

struct DosingPlannerView: View {
    @State private var archetype: MVArchetype = .standardAdult
    @State private var rule = MVDosingRule()
//    @State private var quiet: ClosedRange<Int> = 23...7
    @State private var quiet = MVQuietWindow(start: 23, end: 7)
    
    @State private var plan: MVDosingPlan? = nil
    @State private var enableReminder: Bool = false
    @State private var frequencyModeIndex: Int = 0 // 0: daily  1: qXh  2: everyNDays
    @State private var everyXHours: Int = 8
    @FocusState private var noteFocused: Bool

    private let archetypes: [MVArchetype] = [.standardAdult, .earlyBird, .nightOwl, .elderly]

    var body: some View {
        
        Form {
            Section(header: Text("用药方案")) {
                Picker("频率", selection: $frequencyModeIndex) {
                    Text("每日定次").tag(0)
                    Text("每X小时").tag(1)
                    Text("每N天").tag(2)
                }.pickerStyle(.segmented)
                
                if frequencyModeIndex == 0 {
                    Stepper(value: Binding(get: {
                        if case .daily(let n) = rule.frequency { return n } else { return 1 }
                    }, set: { rule.frequency = .daily(timesPerDay: $0) }), in: 1...6) {
                        Text("每日定次：\(currentTimesPerDay()) 次/日")
                    }
                } else if frequencyModeIndex == 1 {
                    Stepper(value: $everyXHours, in: 4...24) {
                        Text("每 \(everyXHours) 小时一次")
                    }.onChange(of: everyXHours) { rule.frequency = .everyXHours(everyXHours) }
                } else {
                    // 简化：N 天一次，仍允许设置当日次数
                    HStack {
                        Stepper(value: Binding(get: {
                            if case .everyNDays(let n, _) = rule.frequency { return n } else { return 2 }
                        }, set: { n in
                            let times = currentTimesPerDay()
                            rule.frequency = .everyNDays(n, timesPerDay: times)
                        }), in: 2...14) {
                            Text("每 N 天：\(currentNDays()) 天")
                        }
                    }
                    Stepper(value: Binding(get: { currentTimesPerDay() }, set: { t in
                        if case .everyNDays(let n, _) = rule.frequency { rule.frequency = .everyNDays(n, timesPerDay: t) }
                    }), in: 1...6) { Text("当日 \(currentTimesPerDay()) 次") }
                }
                
                Stepper(value: $rule.durationDays, in: 1...60) { Text("按天计算：\(rule.durationDays) 天") }
            }
            
            Section(header: Text("用药说明")) {
                timingPicker
                methodsToggles
                TextField("自定义用药说明（可选）", text: $rule.customNote)
                    .focused($noteFocused)
            }
            
            Section(header: Text("作息与约束")) {
                Picker("作息模板", selection: $archetype) {
                    ForEach(archetypes) { a in Text(a.name).tag(a) }
                }
                Toggle("严格间隔（夜间不回避）", isOn: $rule.strictInterval)
                DatePicker("起始锚点", selection: $rule.startAnchor, displayedComponents: [.date, .hourAndMinute])
                HStack {
                    Text("夜间回避：\(quiet.start):00 - \(quiet.end):00")
                    Spacer()
                    Stepper("") {
                        quiet.start = (quiet.start + 1) % 24
                    } onDecrement: {
                        quiet.start = (quiet.start + 23) % 24
                    }
                    .labelsHidden()
                    
                    Stepper("") {
                        quiet.end = (quiet.end + 1) % 24
                    } onDecrement: {
                        quiet.end = (quiet.end + 23) % 24
                    }
                    .labelsHidden()
                }
                Stepper("整体平移") {
                    quiet.start = (quiet.start + 1) % 24
                    quiet.end   = (quiet.end + 1) % 24
                } onDecrement: {
                    quiet.start = (quiet.start + 23) % 24
                    quiet.end   = (quiet.end + 23) % 24
                }
            }
            
            if let plan {
                Section(header: Text("智能计算提醒时间")) {
                    ForEach(plan.schedule.indices, id: \.self) { idx in
                        HStack {
                            DatePicker("第 \(idx+1) 次", selection: Binding(get: { plan.schedule[idx].planned }, set: { new in
                                self.plan?.schedule[idx].planned = new
                            }), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                        }
                    }
                }
            }
            
            Section(header: Text("当前用药方案")) {
                Text(summaryText).font(.callout)
                Button("智能计算提醒时间") { computePlan() }
                    .buttonStyle(.borderedProminent)
                Toggle("用药提醒（本地通知）", isOn: $enableReminder)
                    .onChange(of: enableReminder) { newValue in
                        Task { await handleReminderToggle(newValue) }
                    }
            }
        }
        .navigationTitle("用药方案")
        
    }

    // MARK: - Subviews
    private var timingPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("与作息关系（单选）").font(.subheadline).foregroundStyle(.secondary)
            Picker("与作息关系", selection: $rule.timing) {
                ForEach(MVTiming.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }.pickerStyle(.segmented)
        }
    }

    private var methodsToggles: some View {
        VStack(alignment: .leading) {
            Text("方式与说明（多选）").font(.subheadline).foregroundStyle(.secondary)
            WrapHStack(spacing: 8) {
                methodToggle("温水送服", .warmWater)
                methodToggle("嚼服", .chew)
                methodToggle("含服", .dissolve)
                methodToggle("外用", .external)
                methodToggle("遵医嘱", .asDirected)
            }
        }
    }

    @ViewBuilder private func methodToggle(_ label: String, _ flag: MVMethod) -> some View {
        let isOn = Binding<Bool>(get: { rule.methods.contains(flag) }, set: { new in
            if new { rule.methods.insert(flag) } else { rule.methods.remove(flag) }
        })
        Toggle(label, isOn: isOn)
            .toggleStyle(.switch)
            .tint(.blue)
    }

    // MARK: - Helpers

    private var summaryText: String {
        switch rule.frequency {
        case .daily(let n):
            return "每日\(n)次 · 连续\(rule.durationDays)天"
        case .everyXHours(let h):
            return "每\(h)小时一次 · 持续\(rule.durationDays)天"
        case .everyNDays(let n, let t):
            return "每\(n)天 · 当日\(t)次 · 持续\(rule.durationDays)天"
        }
    }

    private func currentTimesPerDay() -> Int {
        switch rule.frequency { case .daily(let n): return n; case .everyNDays(_, let t): return t; default: return 1 }
    }
    private func currentNDays() -> Int {
        if case .everyNDays(let n, _) = rule.frequency { return n } else { return 2 }
    }

    private func computePlan() {
        // 将 UI 状态组合为计划
        switch frequencyModeIndex {
        case 0: if case .daily = rule.frequency { break } else { rule.frequency = .daily(timesPerDay: 1) }
        case 1: rule.frequency = .everyXHours(everyXHours)
        case 2: if case .everyNDays = rule.frequency { } else { rule.frequency = .everyNDays(2, timesPerDay: currentTimesPerDay()) }
        default: break
        }
        let p = MVPlanner.generate(rule: rule, archetype: archetype, quiet: quiet)
        self.plan = p
    }

    private func handleReminderToggle(_ enabled: Bool) async {
        guard let plan else { return }
        if enabled {
            do {
                let ok = try await MVNotificationCenter.shared.requestAuthorization()
                if ok { await MVNotificationCenter.shared.schedule(plan: plan, title: "用药提醒", body: summaryText) }
            } catch {
                // 授权失败
            }
        } else {
            await MVNotificationCenter.shared.cancel(plan: plan)
        }
    }
}

// MARK: - Simple WrapHStack for toggles
struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    var body: some View {
        FlexibleView(availableWidth: UIScreen.main.bounds.width - 48, spacing: spacing, alignment: .leading, content: content)
    }
}

struct FlexibleView<Content: View>: View {
    let availableWidth: CGFloat
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    @ViewBuilder let content: () -> Content

    var body: some View {
        let elements = Array(Mirror(reflecting: content()).children)
        var width: CGFloat = 0
        var rows: [[AnyView]] = [[]]
        for child in elements {
            if let v = child.value as? AnyView {
                let size = UIHostingController(rootView: v).view.intrinsicContentSize
                if width + size.width + spacing > availableWidth {
                    rows.append([v]); width = size.width + spacing
                } else { rows[rows.count-1].append(v); width += size.width + spacing }
            } else if let v = child.value as? Toggle<Text> { // rough fallback
                let any = AnyView(v)
                rows[rows.count-1].append(any)
            }
        }
        return VStack(alignment: alignment, spacing: spacing) {
            content()
        }
    }
}

// MARK: - Preview
struct DosingPlannerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DosingPlannerView()

        }
    }
}
