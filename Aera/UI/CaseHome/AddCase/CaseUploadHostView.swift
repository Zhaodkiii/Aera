//
//  CaseUploadHostView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/20.
//

import SwiftUI


struct CaseUploadHostView: View {
    @State private var showCaseSourceMenu = true          // 你的条件
    @State private var pickedImages: [UIImage] = []
    @State private var pickedDocs: [URL] = []
    @State private var showProcessing = false
    
    var body: some View {
//        NavigationStack {
//
//            .navigationTitle("新增病例")
//        }
        ZStack {
            Color.white.ignoresSafeArea()
            
            // 选择来源页
            if showCaseSourceMenu {
                CaseUploadChoiceView(mode: .caseDocument, allowPDF: true) { images, documents in
                    pickedImages = images
                    pickedDocs = documents
                    withAnimation { showProcessing = true }      // → 显示等待页
                }
            }
            
            // 等待页（覆盖在上层）
            if showProcessing {
                Color.white.ignoresSafeArea()
                RecognizeProcessingView(
                    images: pickedImages,
                    documents: pickedDocs,
                    recognize: demoRecognize                  // ← 直接传实现
                )
                .transition(.opacity)
            }
        }
    }
    
    // Demo：阶段推进（上传→OCR→分析→生成）
    func demoRecognize(
        images: [UIImage],
        documents: [URL],
        progress: @escaping (Double, RecognizeStage) async -> Void
    ) async throws -> RecognizedCase {
        // 总时长可调
        try await withTaskCancellationHandler(operation: {
            // 上传 0~0.25
            await progress(0.05, .upload)
            try await Task.sleep(nanoseconds: 800_000_000)
            await progress(0.22, .upload)
            
            // OCR 0.25~0.55
            await progress(0.28, .ocr)
            try await Task.sleep(nanoseconds: 800_000_000)
            await progress(0.52, .ocr)
            
            // 智能分析 0.55~0.85
            await progress(0.58, .analyze)
            try await Task.sleep(nanoseconds: 800_000_000)
            await progress(0.82, .analyze)
            
            // 生成结果 0.85~1
            await progress(0.9, .generate)
            try await Task.sleep(nanoseconds: 600_000_000)
            await progress(1.0, .generate)
            
            // 组装识别结果（与之前的 ConfirmRecognizedCaseView 对接）
            let recognized = RecognizedCase(
                confidence: 92,
                patient: .init(name: "李明华", relation: "妈妈", age: 58, gender: "女", caseCount: 1),
                chiefComplaint: "头晕伴恶心呕吐3天",
                diagnosis: "高血压（Essential Hypertension, ICD-10: I10）",
                symptoms: ["头晕","恶心","呕吐","心悸","乏力"],
                firstSymptomDate: makeDate("2024-07-15"),
                diagnosisDate: makeDate("2024-07-20"),
                medications: ["苯磺酸氨氯地平片","厄贝沙坦片"],
                attachments: [.init(name: "病例照片.jpg", type: .image)],
                notes: ""
            )
            return recognized
        }, onCancel: {
            // 如需撤销请求/上传，处理在这里
        })
    }

}
