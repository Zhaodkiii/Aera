//
//  AddCaseEntryView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - 新增病例入口页

struct AddCaseEntryView: View {
    @State private var showPhotoPickerForCase = false
    @State private var showPhotoPickerForExam = false
    @State private var showDocPickerForCase = false
    @State private var showDocPickerForExam = false
    
    @State private var pickedCaseItems: [PhotosPickerItem] = []
    @State private var pickedExamItems: [PhotosPickerItem] = []
    @State private var pickedCaseDocs: [URL] = []
    @State private var pickedExamDocs: [URL] = []
    // MARK: 源选择（ActionSheet 风格）
    @State private var showCaseSourceMenu = false
    @State private var showExamSourceMenu = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
//                // 1) 上传医院病例/检查单
//                ActionCardLink(
//                    iconSystemName: "doc.text.fill",
//                    iconBG: .blue.opacity(0.12),
//                    iconFG: .blue,
//                    title: "上传医院病例/检查单",
//                    subtitle: "支持拍照上传、相册选择、PDF 文件\n自动识别患者信息、诊断和用药",
//                    buttonTitle: "选择病例/检查单",
//                    buttonStyle: .primaryBlue
//                ) {
//                    CaseUploadChoiceView(mode: .caseDocument, allowPDF: true)
//                }
//
//                
//                ActionCardLink(
//                    iconSystemName: "waveform.path.ecg.rectangle.fill",
//                    iconBG: .green.opacity(0.12),
//                    iconFG: .green,
//                    title: "上传体检报告",
//                    subtitle: "支持 JPG/PNG/PDF 格式\n自动识别体检项目、检查结果和异常提示",
//                    buttonTitle: "选择体检报告",
//                    buttonStyle: .primaryGreen
//                ) {
//                    CaseUploadChoiceView(mode: .checkupReport, allowPDF: true) 
//                }
                // 1) 上传医院病例/检查单
                ActionCard(
                    iconSystemName: "doc.text.fill",
                    iconBG: .blue.opacity(0.12),
                    iconFG: .blue,
                    title: "上传医院病例/检查单",
                    subtitle: "支持拍照上传、相册选择、PDF 文件\n自动识别患者信息、诊断和用药",
                    buttonTitle: "选择病例/检查单",
                    buttonStyle: .primaryBlue
                ) {
                    // 你可以选择打开相册或文件，这里给两种入口
                    showSourceMenuForCase()
                }
//                .overlay(sourceMenuForCase)
                
                // 2) 上传体检报告
                ActionCard(
                    iconSystemName: "waveform.path.ecg.rectangle.fill",
                    iconBG: .green.opacity(0.12),
                    iconFG: .green,
                    title: "上传体检报告",
                    subtitle: "支持 JPG/PNG/PDF 格式\n自动识别体检项目、检查结果和异常提示",
                    buttonTitle: "选择体检报告",
                    buttonStyle: .primaryGreen
                ) {
                    showSourceMenuForExam()
                }
//                .overlay(sourceMenuForExam)
//
                // 3) 手工录入
                NavigationLink {
                    ManualCaseFormView()
                } label: {
                    ActionCard(
                        iconSystemName: "pencil.and.outline",
                        iconBG: .orange.opacity(0.15),
                        iconFG: .orange,
                        title: "手工录入",
                        subtitle: "手动输入患者信息和病情记录\n适用于详细记录和完全自定义输入",
                        buttonTitle: "开始手工录入",
                        buttonStyle: .primaryOrange,
                        action: {}
                    )
                }
                .buttonStyle(.plain)
                
                // 选择结果（演示用，可删）
                if !(pickedCaseItems.isEmpty && pickedCaseDocs.isEmpty && pickedExamItems.isEmpty && pickedExamDocs.isEmpty) {
                    ResultPreview(
                        pickedCaseItems: pickedCaseItems.count,
                        pickedCaseDocs: pickedCaseDocs.count,
                        pickedExamItems: pickedExamItems.count,
                        pickedExamDocs: pickedExamDocs.count
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .overlay(
            sourceMenuForCase
            
        )
        .navigationTitle("新增病例")
        .photosPicker(isPresented: $showPhotoPickerForCase, selection: $pickedCaseItems, maxSelectionCount: 10, matching: .images)
        .photosPicker(isPresented: $showPhotoPickerForExam, selection: $pickedExamItems, maxSelectionCount: 10, matching: .images)
        .sheet(isPresented: $showDocPickerForCase) {
            DocPicker(allowed: [.pdf, .png, .jpeg, .heic]) { urls in
                pickedCaseDocs = urls
            }
        }
        .sheet(isPresented: $showDocPickerForExam) {
            DocPicker(allowed: [.pdf, .png, .jpeg, .heic]) { urls in
                pickedExamDocs = urls
            }
        }
    }
    
 
    
    private func showSourceMenuForCase() { showCaseSourceMenu = true }
    private func showSourceMenuForExam() { showExamSourceMenu = true }
    
    @ViewBuilder private var sourceMenuForCase: some View {
        if showCaseSourceMenu {
            
            ZStack{
                Color.white.ignoresSafeArea()
                CaseUploadHostView()
            }
//            ZStack{
//                Color.white.ignoresSafeArea()
//                CaseUploadChoiceView(mode: .caseDocument, allowPDF: true){images, documents in
//                    Task{
//                        do{
//                            try await demoRecognize(images: images, documents: documents) { fsdfds, RecognizeStage in
//                              
//
//                            }
//                        }catch{
//                            
//                        }
//                    }
//                   
//                }
//                
//                RecognizeProcessingView( recognize: <#([UIImage], [URL], @escaping (Double, RecognizeStage) async -> Void) async throws -> RecognizedCase#>)
//            }
        }
    }
    @ViewBuilder private var sourceMenuForExam: some View {
        if showExamSourceMenu {
            SourceMenu { action in
                showExamSourceMenu = false
                switch action {
                case .photo: showPhotoPickerForExam = true
                case .file:  showDocPickerForExam = true
                }
            }
        }
    }
    
    // Demo：阶段推进（上传→OCR→分析→生成）
    func demoRecognize(
        images: [UIImage],
        documents: [URL],
        progress: @escaping (Double, RecognizeStage) -> Void
    ) async throws -> RecognizedCase {
        // 总时长可调
        try await withTaskCancellationHandler(operation: {
            // 上传 0~0.25
            progress(0.05, .upload)
            try await Task.sleep(nanoseconds: 800_000_000)
            progress(0.22, .upload)
            
            // OCR 0.25~0.55
            progress(0.28, .ocr)
            try await Task.sleep(nanoseconds: 800_000_000)
            progress(0.52, .ocr)
            
            // 智能分析 0.55~0.85
            progress(0.58, .analyze)
            try await Task.sleep(nanoseconds: 800_000_000)
            progress(0.82, .analyze)
            
            // 生成结果 0.85~1
            progress(0.9, .generate)
            try await Task.sleep(nanoseconds: 600_000_000)
            progress(1.0, .generate)
            
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

// MARK: - 手工录入表单页（可直接保存/预览）

struct ManualCaseFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var patientName = ""
    @State private var relationship = ""
    @State private var gender = "男"
    @State private var age = ""
    @State private var chiefComplaint = ""
    @State private var diagnosis = ""
    @State private var symptomsText = ""
    @State private var medicationsText = ""
    @State private var status = "治疗中"
    @State private var severity = "中"
    @State private var visitDate = Date()
    @State private var notes = ""
    @State private var isFavorite = false
    
    private let genders = ["男", "女"]
    private let statuses = ["慢性管理", "治疗中", "复查中", "已治愈"]
    private let severities = ["轻", "中", "重"]
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("患者姓名", text: $patientName)
                HStack {
                    TextField("年龄", text: $age)
                        .keyboardType(.numberPad)
                    Picker("性别", selection: $gender) {
                        ForEach(genders, id: \.self, content: Text.init)
                    }
                }
                TextField("关系（如：本人/爸爸/妈妈…）", text: $relationship)
                DatePicker("就诊日期", selection: $visitDate, displayedComponents: .date)
                Toggle("收藏", isOn: $isFavorite)
            }
            Section("病情记录") {
                TextField("主诉（如：头晕伴恶心呕吐3天）", text: $chiefComplaint)
                TextField("诊断（如：高血压、颈椎病）", text: $diagnosis)
                Picker("严重程度", selection: $severity) {
                    ForEach(severities, id: \.self, content: Text.init)
                }
                Picker("当前状态", selection: $status) {
                    ForEach(statuses, id: \.self, content: Text.init)
                }
                TextField("症状（逗号分隔，如：头晕, 恶心, 呕吐）", text: $symptomsText)
                TextField("用药（逗号分隔，如：氨氯地平, 颈复康颗粒）", text: $medicationsText)
                TextField("备注提示", text: $notes)
            }
            Section {
                Button {
                    // 这里把表单转成你的 CaseItem（或提交到后端）
                    // …保存逻辑自行接入
                    dismiss()
                } label: {
                    Text("保存病例")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("手工录入")
    }
}

// MARK: - UI 组件
import SwiftUI

/// 仅按钮触发跳转的卡片
struct ActionCardLink<Destination: View>: View {
    enum ButtonStyleKind { case primaryBlue, primaryGreen, primaryOrange }

    let iconSystemName: String
    let iconBG: Color
    let iconFG: Color
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonStyle: ButtonStyleKind
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(iconBG).frame(width: 64, height: 64)
                    Image(systemName: iconSystemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(iconFG)
                }
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            NavigationLink(destination: destination()) {
                HStack(spacing: 8) {
                    icon
                    Text(buttonTitle).font(.subheadline.weight(.semibold))
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(buttonBG)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder private var icon: some View {
        switch buttonStyle {
        case .primaryBlue:   Image(systemName: "square.and.arrow.up.on.square.fill")
        case .primaryGreen:  Image(systemName: "square.and.arrow.up.on.square.fill")
        case .primaryOrange: Image(systemName: "pencil.line")
        }
    }
    private var buttonBG: some ShapeStyle {
        switch buttonStyle {
        case .primaryBlue:   AnyShapeStyle(Color.blue)
        case .primaryGreen:  AnyShapeStyle(Color.green)
        case .primaryOrange: AnyShapeStyle(Color.orange)
        }
    }
}

/// 通用卡片
struct ActionCard: View {
    enum ButtonStyleKind { case primaryBlue, primaryGreen, primaryOrange }
    
    let iconSystemName: String
    let iconBG: Color
    let iconFG: Color
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonStyle: ButtonStyleKind
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(iconBG).frame(width: 64, height: 64)
                    Image(systemName: iconSystemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(iconFG)
                }
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Button(action: action) {
                HStack(spacing: 8) {
                    icon
                    Text(buttonTitle).font(.subheadline.weight(.semibold))
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .background(buttonBG)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder private var icon: some View {
        switch buttonStyle {
        case .primaryBlue:   Image(systemName: "square.and.arrow.up.on.square.fill")
        case .primaryGreen:  Image(systemName: "square.and.arrow.up.on.square.fill")
        case .primaryOrange: Image(systemName: "pencil.line")
        }
    }
    private var buttonBG: some ShapeStyle {
        switch buttonStyle {
        case .primaryBlue:   return AnyShapeStyle(Color.blue)
        case .primaryGreen:  return AnyShapeStyle(Color.green)
        case .primaryOrange: return AnyShapeStyle(Color.orange)
        }
    }
}

/// 底部弹出的源选择（相册/文件），轻量模拟 ActionSheet
fileprivate struct SourceMenu: View {
    enum Action { case photo, file }
    var onSelect: (Action) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                SourceRow(title: "从相册选择", system: "photo.on.rectangle") { onSelect(.photo) }
                Divider()
                SourceRow(title: "选择文件（PDF/JPG/PNG）", system: "doc") { onSelect(.file) }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            Button(role: .cancel) { onSelect(.file); /* 立即关闭由上层控制 */ } label: {
                Text("取消").frame(maxWidth: .infinity)
            }
            .padding(.top, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(0.001) // 点击空白处也能关闭的简化处理，由父视图置 false
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color.black.opacity(0.15).ignoresSafeArea())
        .onTapGesture { /* 由父层关闭 */ }
    }
    private struct SourceRow: View {
        let title: String
        let system: String
        let action: () -> Void
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: system)
                    Text(title)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
            }
            .buttonStyle(.plain)
        }
    }
}

/// 结果预览（演示）
fileprivate struct ResultPreview: View {
    let pickedCaseItems: Int
    let pickedCaseDocs: Int
    let pickedExamItems: Int
    let pickedExamDocs: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择结果（调试展示，可移除）").font(.footnote).foregroundStyle(.secondary)
            HStack {
                Label("病例图片 \(pickedCaseItems) 张", systemImage: "photo")
                Spacer()
                Label("病例文件 \(pickedCaseDocs) 个", systemImage: "doc")
            }.font(.footnote)
            HStack {
                Label("体检图片 \(pickedExamItems) 张", systemImage: "photo")
                Spacer()
                Label("体检文件 \(pickedExamDocs) 个", systemImage: "doc")
            }.font(.footnote)
        }
        .padding(12)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}



// MARK: - 预览

struct AddCaseEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { AddCaseEntryView() }
            .environment(\.locale, .init(identifier: "zh-Hans"))
    }
}
