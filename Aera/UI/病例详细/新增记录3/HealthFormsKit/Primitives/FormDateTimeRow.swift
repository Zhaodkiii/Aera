//
//  FormDateTimeRow.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/21.
//

import SwiftUI
import SwiftUI

// HealthFormsKit • Sections
// 公共日期+时间两列区域：替代页面内重复的 GridTwo + DatePicker 组合
public struct FormDateTimeRow: View {
    @Environment(\.colorScheme) private var scheme

    @Binding private var date: Date
    @Binding private var time: Date

    private let dateLabel: String
    private let timeLabel: String
    private let required: Bool

    /// - Parameters:
    ///   - date: 绑定到“日期”的值
    ///   - time: 绑定到“时间”的值
    ///   - dateLabel: 左侧标签（默认“日期”）
    ///   - timeLabel: 右侧标签（默认“时间”）
    ///   - required: 是否必填（影响标签上的 * 展示）
    public init(
        date: Binding<Date>,
        time: Binding<Date>,
        dateLabel: String = "日期",
        timeLabel: String = "时间",
        required: Bool = true
    ) {
        self._date = date
        self._time = time
        self.dateLabel = dateLabel
        self.timeLabel = timeLabel
        self.required = required
    }

    public var body: some View {
        GridTwo {
            VStack(alignment: .leading, spacing: 8) {
                FormLabel(dateLabel, required: required)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .formFieldChrome()
            }
            VStack(alignment: .leading, spacing: 8) {
                FormLabel(timeLabel, required: required)
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .formFieldChrome()
            }
        }
    }
}

// 可选：仅日期或仅时间版本，便于不同页面按需复用
public struct FormDateRow: View {
    @Binding private var date: Date
    private let label: String
    private let required: Bool
    public init(_ label: String = "日期", required: Bool = true, date: Binding<Date>) {
        self.label = label
        self.required = required
        self._date = date
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormLabel(label, required: required)
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .formFieldChrome()
        }
    }
}

public struct FormTimeRow: View {
    @Binding private var time: Date
    private let label: String
    private let required: Bool
    public init(_ label: String = "时间", required: Bool = true, time: Binding<Date>) {
        self.label = label
        self.required = required
        self._time = time
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FormLabel(label, required: required)
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .formFieldChrome()
        }
    }
}
