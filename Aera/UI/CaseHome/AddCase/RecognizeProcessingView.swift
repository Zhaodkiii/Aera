//
//  RecognizeProcessingView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/20.
//

import SwiftUI

// 识别阶段
 enum RecognizeStage: Int, CaseIterable {
    case upload = 0, ocr, analyze, generate
    
    var title: String {
        switch self {
        case .upload:   return "文件上传"
        case .ocr:      return "文字识别"
        case .analyze:  return "智能分析"
        case .generate: return "生成结果"
        }
    }
}

// 等待页：负责显示动画/进度，并在完成后导航到确认页
struct RecognizeProcessingView: View {
    // 你可传入图片/文件地址，供识别使用
    var images: [UIImage] = []
    var documents: [URL] = []
    
    /// 识别逻辑（替换为你的真实实现）
    // 把 View 里依赖的函数签名改为 async 回调
    var recognize: (_ images: [UIImage],
                    _ documents: [URL],
                    _ progress: @escaping (Double, RecognizeStage) async -> Void) async throws -> RecognizedCase

    // 导航
    @State private var goToConfirm = false
    @State private var result: RecognizedCase?
    
    // UI 状态
    @State private var progress: Double = 0.0   // 0~1
    @State private var stage: RecognizeStage = .upload
    @State private var etaText: String = "--"
    @State private var isWorking = true
    @State private var error: String?
    
    // 估算剩余时间（简单估算：根据进度线性推算）
    private func updateETA() {
        guard progress > 0, isWorking else { etaText = "--"; return }
        let remaining = (1 - progress)
        // 假定总时长 8 秒，按需调整或换为服务端返回
        let seconds = max(1, Int(ceil(remaining * 8)))
        etaText = "预计还需 \(seconds) 秒"
    }
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()
                
                // 中心动画（脑袋 + 旋转环）
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "brain.head.profile") // iOS 17；iOS16可换为 "brain" 自定义图
                                .font(.system(size: 36, weight: .regular))
                                .foregroundStyle(.blue)
                                .scaleEffect(1.02)
                                .opacity(0.95)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: isWorking)
                        )
                    
                    Circle()
                        .trim(from: 0, to: 0.85)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isWorking ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isWorking)
                }
                .padding(.bottom, 6)
                
                VStack(spacing: 6) {
                    Text("智能识别中").font(.title3).foregroundStyle(.primary)
                    Text(stageTitle(stage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // 进度条 + 数字
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .frame(maxWidth: 360)
                    
                    HStack {
                        Text("进度 \(Int(progress * 100))%")
                        Spacer()
                        Text(etaText)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 360)
                }
                
                // 信息卡：任务名/副标题
                HStack(spacing: 10) {
                    ProgressView().tint(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("医疗病例识别").font(.subheadline).foregroundStyle(.primary)
                        Text("AI 正在分析您上传的文档…")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: 360)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.25)))
                
                // 步骤
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(RecognizeStage.allCases, id: \.rawValue) { s in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(dotColor(for: s))
                                .frame(width: 8, height: 8)
                            Text(stepLine(for: s))
                                .font(.subheadline)
                                .foregroundStyle(textColor(for: s))
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: 360)
                .padding(.top, 4)
                
                Spacer()
                
                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.bottom, 8)
                }
                
                // （可选）取消按钮
                Button {
                    // 如果需要取消上报任务，这里触发取消逻辑（例如 Task.cancel / abort request）
                    isWorking = false
                    error = "已取消"
                } label: {
                    Text("取消")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(isWorking ? 1 : 0.6)
                .disabled(!isWorking)
                
                // 导航占位（隐藏跳转）
                NavigationLink(isActive: $goToConfirm) {
                    if let result {
                        ConfirmRecognizedCaseView(form: result) { _ in
                            // 保存回调
                            dismiss()   // 👈 pop 出去

                        }
                    } else {
                        EmptyView()
                    }
                } label: { EmptyView() }
                .hidden()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await startRecognize()
        }
        .onChange(of: progress) { _ in updateETA() }

    }
    
    private func stageTitle(_ s: RecognizeStage) -> String {
        switch s {
        case .upload:   return "上传中…"
        case .ocr:      return "文字识别中…"
        case .analyze:  return "智能分析中…"
        case .generate: return "生成结果中…"
        }
    }
    private func dotColor(for s: RecognizeStage) -> Color {
        if s.rawValue < stage.rawValue { return .green }          // 已完成
        if s == stage { return .blue }                            // 进行中
        return .gray.opacity(0.4)                                 // 未开始
    }
    private func textColor(for s: RecognizeStage) -> Color {
        if s.rawValue < stage.rawValue { return .green }
        if s == stage { return .blue }
        return .secondary
    }
    private func stepLine(for s: RecognizeStage) -> String {
        switch s {
        case .upload:   return "文件上传"
        case .ocr:      return "文字识别"
        case .analyze:  return "智能分析"
        case .generate: return "生成结果"
        }
    }
    // 启动识别
    private func startRecognize() async {
        isWorking = true
        error = nil
        do {
            let recognized = try await recognize(images, documents) { p, st in
                // 注意：这里不要用 await MainActor.run
                Task { @MainActor in
                    self.progress = min(max(p, 0), 1)
                    self.stage = st
                }
            }
            await MainActor.run {
                self.result = recognized
                self.isWorking = false
                self.progress = 1
                self.stage = .generate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.goToConfirm = true
                }
            }
        } catch {
            await MainActor.run {
                self.isWorking = false
                self.error = "识别失败，请重试：\(error.localizedDescription)"
            }
        }
    }

}
