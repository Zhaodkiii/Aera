//
//  CDNewRecordScreen.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI

import SwiftUI
import PhotosUI
// MARK: - 新增入口路由（避免与已有 CDNewRoute 重名）
enum CDCreateRoute: Hashable, Identifiable {
    case report
    case symptom
    case visit
    case medication
    case measurement
    case followup

    var id: String { // 为 .navigationDestination(item:) 提供 Identifiable
        switch self {
        case .report:      return "report"
        case .symptom:     return "symptom"
        case .visit:       return "visit"
        case .medication:  return "medication"
        case .measurement: return "measurement"
        case .followup:    return "followup"
        }
    }
}

// MARK: - 新增记录入口
struct CDNewRecordScreen: View {
    @State private var createRoute: CDCreateRoute? = nil
    @State private var showQuickUpload = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部说明
                VStack(spacing: 6) {
                    Text("请选择要添加的记录类型")
                        .font(.headline)
                    Text("选择后将进入对应的表单页面")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    CDNewTypeCard(emoji: "📄", title: "检查报告", tint: .blue) { createRoute = .report }
                    CDNewTypeCard(emoji: "🤒", title: "症状", tint: .orange) { createRoute = .symptom }
                    CDNewTypeCard(emoji: "🩺", title: "就医", tint: .green) { createRoute = .visit }
                    CDNewTypeCard(emoji: "💊", title: "用药", tint: .purple) { createRoute = .medication }
                    CDNewTypeCard(emoji: "🔬", title: "测量", tint: .teal) { createRoute = .measurement }
                    CDNewTypeCard(emoji: "📞", title: "随访", tint: .gray) { createRoute = .followup }
                }
                .padding(.horizontal, 16)

                .padding(.horizontal, 16)

                // 快速上传检查报告
                CDNewQuickUploadCard(
                    title: "快速添加检查报告",
                    subtitle: "拍照或上传 PDF，自动识别报告内容",
                    actionTitle: "开始上传识别"
                ) { showQuickUpload = true }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
//            .background(Color(.systemGroupedBackground))
        .navigationTitle("新增记录")
        .navigationBarTitleDisplayMode(.inline)
        // 假设外部有：@State private var route: CDEventKind? = nil

    
        // 跳转
        .navigationDestination(item: $createRoute) { route in
            switch route {
            case .report:
                CDReportFormView { saved in
                    // TODO: 回写 saved 到数据源
                }
            case .symptom:
                CDSymptomFormView { saved in
                    // TODO: 回写 saved 到数据源
                }
            case .visit:
                CDVisitFormView { saved in
                    // TODO: 回写 saved 到数据源
                }
            case .medication:
                CDMedicationFormView { saved in
                    // TODO: 回写 saved 到数据源
                }
//            default:
//                Text("该类型表单待实现")
            case .measurement:
                CDSurgeryFormView{ saved in
                    // TODO: 回写 saved 到数据源
                }
            case .followup:
                CDFollowupFormView{ saved in
                    // TODO: 回写 saved 到数据源
                }
            }
        }
        .sheet(isPresented: $showQuickUpload) {
            CDNewQuickUploaderSheet()
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - 路由桥接（NavigationDestination 需 Identifiable）
//private struct CDNewRoute: Identifiable {
//    let id = UUID()
//    let kind: CDEventKind
//}

// 用于“新增记录”路由的数据模型
struct CDNewRoute: Identifiable, Hashable {
    let kind: CDEventKind
    // 以 kind 作为稳定 id，避免每次都生成新的 UUID
    var id: CDEventKind { kind }
}
// MARK: - 类型卡片
private struct CDNewTypeCard: View {
    let emoji: String
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji).font(.system(size: 28))
                Text(title).font(.subheadline)
            }
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(tint.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.25), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 快捷上传卡片
private struct CDNewQuickUploadCard: View {
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.15))
                    Image(systemName: "camera")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .frame(width: 48, height: 48)

                Text(title).font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [6])))
    }
}

// MARK: - 表单 VM
@MainActor
final class CDNewFormModel: ObservableObject {
    let kind: CDEventKind

    @Published var date: Date = .init()
    @Published var time: Date = .init()
    @Published var hasTime: Bool = false

    @Published var title: String = ""
    @Published var detail: String = ""

    @Published var author: String = ""
    @Published var clinical: CDClinicalSeverity? = nil
    @Published var signal: CDSignalSeverity? = nil

    @Published var attachments: [CDAttachment] = []
    @Published var pickedPhotos: [PhotosPickerItem] = []

    init(kind: CDEventKind) { self.kind = kind }
}


// MARK: - 快速上传弹窗（占位演示）
private struct CDNewQuickUploaderSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Spacer()
                ZStack {
                    Circle().fill(Color.blue.opacity(0.15))
                    Image(systemName: "doc.text.viewfinder").foregroundStyle(.blue)
                }
                .frame(width: 72, height: 72)
                Text("上传或拍照识别报告").font(.title3).bold()
                Text("这里可接入 OCR / NLP 识别并预填表单").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("选择文件/拍照（占位）") {}
                    .buttonStyle(.borderedProminent)
                Button("关闭") { dismiss() }
                    .padding(.top, 4)
                Spacer(minLength: 12)
            }
            .padding(20)
            .navigationTitle("快速上传")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 预览
struct CDNewRecordScreen_Previews: PreviewProvider {
    static var previews: some View {
        
            NavigationStack {
                CDNewRecordScreen()
            }
        
    }
}
