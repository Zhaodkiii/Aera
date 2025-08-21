//
//  AddEventRecordView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//

import SwiftUI
import SwiftUI
import PhotosUI

// MARK: - Models

struct ClinicMedicalRecord: Identifiable, Hashable {
    var id: String
    var patientName: String
    var age: Int
    var gender: String // "男" | "女"
}

enum ClinicEventType: String, CaseIterable, Identifiable {
    case report, symptom, medical, medication, surgery, followup
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .report: return "检查报告"
        case .symptom: return "症状"
        case .medical: return "就医"
        case .medication: return "用药"
        case .surgery: return "手术"
        case .followup: return "随访"
        }
    }
    
    var emoji: String {
        switch self {
        case .report: return "📄"
        case .symptom: return "🤒"
        case .medical: return "🩺"
        case .medication: return "💊"
        case .surgery: return "🔪"
        case .followup: return "📞"
        }
    }
    
    var tint: Color {
        switch self {
        case .report: return .blue
        case .symptom: return .orange
        case .medical: return .green
        case .medication: return .purple
        case .surgery: return .red
        case .followup: return .gray
        }
    }
}

struct ClinicAttachment: Identifiable, Hashable {
    var id = UUID()
    var name: String
}

struct ClinicEventFormData: Identifiable {
    var id = UUID()
    var type: ClinicEventType = .report
    var date: Date = .init()
    var title: String = ""
    var description: String = ""
    var attachments: [ClinicAttachment] = []
    
    // 通用可选
    var severity: String? // low | medium | high
    
    // 报告
    var reportName: String? = nil
    var checkType: String? = nil
    var conclusion: String? = nil
    var doctorAdvice: String? = nil
    
    // 就医
    var hospital: String? = nil
    var department: String? = nil
    var visitType: String? = nil // 门诊/急诊/住院/体检
    var diagnosis: String? = nil
    var treatment: String? = nil
    
    // 用药
    var medicationName: String? = nil
    var dosage: String? = nil
    var frequency: String? = nil
    var duration: String? = nil
    
    // 手术
    var surgeryName: String? = nil
    var surgeon: String? = nil
    var anesthesia: String? = nil
    var complications: String? = nil
}

// MARK: - View

struct AddEventRecordView: View {
    // 输入
    var record: ClinicMedicalRecord
    var onBack: (() -> Void)?
    var onSave: ((ClinicEventFormData) -> Void)?
    
    // 状态
    @State private var selectedType: ClinicEventType? = nil
    @State private var formData = ClinicEventFormData()
    @State private var isSubmitting = false
    @State private var isProcessingOCR = false
    @State private var ocrModeEnabled = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var photosItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if let selectedType {
                    selectedTypeScreen(type: selectedType)
                } else {
                    typeSelectionScreen
                }
            }
            .navigationTitle("新增记录")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                if selectedType == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { onBack?() }) {
                            Image(systemName: "chevron.left")
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { withAnimation { self.selectedType = nil } }) {
                            Image(systemName: "chevron.left")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: enactUltraSave) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Label("保存", systemImage: "checkmark")
                            }
                        }
                        .disabled(isSubmitting)
                    }
                }
            }
        }
        .alert("提示", isPresented: $showAlert, actions: { Button("好", role: .cancel) {} }, message: { Text(alertMessage) })
        .onChange(of: photosItems) { _, newItems in
            Task { await handleQuantumUpload(items: newItems) }
        }
    }
}

// MARK: - Screens
private extension AddEventRecordView {
    var typeSelectionScreen: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("请选择要添加的记录类型")
                    .font(.headline)
                    .padding(.top, 8)
                Text("选择后将进入对应的表单页面")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(ClinicEventType.allCases) { type in
                        Button(action: { selectEventCosmos(type) }) {
                            VStack(spacing: 8) {
                                Text(type.emoji).font(.largeTitle)
                                Text(type.label).font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(type.tint.opacity(0.35)))
                        }
                    }
                }
                .padding(.horizontal)
                
                // OCR 快捷入口
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                        .padding(12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    Text("快速添加检查报告").font(.headline)
                    Text("拍照或上传PDF，自动识别报告内容")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        selectEventCosmos(.report)
                        ocrModeEnabled = true
                    } label: {
                        Label("开始上传识别", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6])))
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
    }
    
    @ViewBuilder
    func selectedTypeScreen(type: ClinicEventType) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                badgeView(for: type)
                if isProcessingOCR {
                    processingCard
                }
                if type == .report && ocrModeEnabled {
                    uploadCard
                }
                basicInfoCard
                if !formData.attachments.isEmpty { attachmentsCard }
                saveButtonLarge
            }
            .padding()
        }
    }
}

// MARK: - Sections
private extension AddEventRecordView {
    func badgeView(for type: ClinicEventType) -> some View {
        HStack { Spacer() ;
            HStack(spacing: 8) {
                Text(type.emoji)
                Text(type.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(type.tint.opacity(0.15))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(type.tint.opacity(0.35)))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            ; Spacer() }
    }
    
    var processingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ProgressView().tint(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("正在识别报告内容...")
                    Text("请稍候，识别完成后可手动修改")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.25)))
    }
    
    var uploadCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.fill.badge.plus")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("上传检查报告")
            Text("支持JPG、PNG、PDF，大小不超过10MB")
                .font(.footnote).foregroundStyle(.secondary)
            PhotosPicker(selection: $photosItems, matching: .images, photoLibrary: .shared()) {
                Label("选择文件", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.gray.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [6])))
    }
    
    var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("基本信息", systemImage: "calendar").font(.headline)
            DatePicker("日期与时间", selection: $formData.date)
                .datePickerStyle(.compact)
            TextField("标题", text: $formData.title)
                .textInputAutocapitalization(.none)
                .submitLabel(.done)
            TextEditor(text: $formData.description)
                .frame(minHeight: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.25)))
                .onAppear { if formData.description.isEmpty { formData.description = "" } }
            
            specificFields
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).stroke(.gray.opacity(0.25)))
    }
    
    @ViewBuilder
    var specificFields: some View {
        switch formData.type {
        case .report:
            Group {
                TextField("报告名称", text: Binding($formData.reportName, replacingNilWith: ""))
                
                Picker("检查类型", selection: Binding($formData.checkType, replacingNilWith: "")) {
                    Text("选择检查类型").tag("")
                    ForEach(["血检","尿检","心电图","X光","CT","MRI","B超","其他"], id: \.self) { Text($0).tag($0) }
                }
                TextField("检查结论", text: Binding($formData.conclusion, replacingNilWith: ""))
                TextField("医生建议", text: Binding($formData.doctorAdvice, replacingNilWith: ""))
            }
        case .symptom:
            Picker("症状严重程度", selection: Binding($formData.severity, replacingNilWith: "")) {
                Text("选择严重程度").tag("")
                Text("轻微").tag("low")
                Text("中等").tag("medium")
                Text("严重").tag("high")
            }
        case .medical:
            Group {
                TextField("医院名称", text: Binding($formData.hospital, replacingNilWith: ""))
                TextField("科室", text: Binding($formData.department, replacingNilWith: ""))
                Picker("就诊类型", selection: Binding($formData.visitType, replacingNilWith: "")) {
                    Text("选择就诊类型").tag("")
                    ForEach(["门诊","急诊","住院","体检"], id: \.self) { Text($0).tag($0) }
                }
                TextField("医生诊断", text: Binding($formData.diagnosis, replacingNilWith: ""))
                TextField("治疗方案", text: Binding($formData.treatment, replacingNilWith: ""))
            }
        case .medication:
            Group {
                TextField("药物名称", text: Binding($formData.medicationName, replacingNilWith: ""))
                TextField("用药剂量", text: Binding($formData.dosage, replacingNilWith: ""))
                Picker("用药频次", selection: Binding($formData.frequency, replacingNilWith: "")) {
                    Text("选择频次").tag("")
                    ForEach(["每日一次","每日两次","每日三次","按需服用"], id: \.self) { Text($0).tag($0) }
                }
                TextField("用药期限", text: Binding($formData.duration, replacingNilWith: ""))
            }
        case .surgery:
            Group {
                TextField("手术名称", text: Binding($formData.surgeryName, replacingNilWith: ""))
                TextField("手术医生", text: Binding($formData.surgeon, replacingNilWith: ""))
                Picker("麻醉方式", selection: Binding($formData.anesthesia, replacingNilWith: "")) {
                    Text("选择麻醉方式").tag("")
                    ForEach(["全身麻醉","局部麻醉","腰麻","硬膜外麻醉"], id: \.self) { Text($0).tag($0) }
                }
                TextField("术后情况", text: Binding($formData.complications, replacingNilWith: ""))
            }
        case .followup:
            Picker("随访方式", selection: Binding($formData.visitType, replacingNilWith: "")) {
                Text("选择随访方式").tag("")
                ForEach(["电话随访","门诊复查","远程咨询","家庭访问"], id: \.self) { Text($0).tag($0) }
            }
        }
    }
    
    var attachmentsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("附件 (\(formData.attachments.count))", systemImage: "paperclip")
                .font(.headline)
            ForEach(Array(formData.attachments.enumerated()), id: \.1.id) { idx, item in
                HStack {
                    Image(systemName: "doc.text")
                    Text(item.name).lineLimit(1)
                    Spacer()
                    Button(role: .destructive) { ejectAttachmentMeteor(idx) } label: {
                        Image(systemName: "xmark")
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.08)))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).stroke(.gray.opacity(0.25)))
    }
    
    var saveButtonLarge: some View {
        Button(action: enactUltraSave) {
            HStack {
                if isSubmitting { ProgressView() } else { Image(systemName: "checkmark") }
                Text(isSubmitting ? "保存中..." : "保存记录")
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSubmitting)
    }
}

// MARK: - Unique Actions
private extension AddEventRecordView {
    func selectEventCosmos(_ type: ClinicEventType) {
        selectedType = type
        formData.type = type
    }
    
    func verifyNebulaForm() -> Bool {
        guard selectedType != nil else { alert("请选择记录类型"); return false }
        guard !formData.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { alert("请输入标题"); return false }
        guard !formData.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { alert("请输入详细描述"); return false }
        return true
    }
    
    func enactUltraSave() {
        guard verifyNebulaForm() else { return }
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSubmitting = false
            onSave?(formData)
            alert("记录保存成功")
        }
    }
    
    func handleQuantumUpload(items: [PhotosPickerItem]) async {
        guard let first = items.first else { return }
        // 仅模拟 OCR 处理
        isProcessingOCR = true
//        await performOrcaMockScan(importedName: first.debugDescription)
        isProcessingOCR = false
    }
    
    func performOrcaMockScan(importedName: String) async {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 模拟耗时
        // 模拟 OCR 识别结果填充
        let mock = (
            reportName: "血常规检查报告",
            checkType: "血检",
            conclusion: "各项指标均在正常范围内",
            doctorAdvice: "建议定期复查，保持健康饮食"
        )
        formData.title = mock.reportName
        formData.reportName = mock.reportName
        formData.checkType = mock.checkType
        formData.conclusion = mock.conclusion
        formData.doctorAdvice = mock.doctorAdvice
        formData.description = "检查结论：\(mock.conclusion)"
        formData.attachments.insert(.init(name: "\(importedName).jpg"), at: 0)
        alert("报告识别成功！请检查并完善信息")
    }
    
    func ejectAttachmentMeteor(_ index: Int) {
        guard formData.attachments.indices.contains(index) else { return }
        formData.attachments.remove(at: index)
    }
    
    func alert(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }
}

// MARK: - Helpers
//private extension Binding where Value == String? {
//    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
//        self.init(get: { source.wrappedValue ?? defaultValue }, set: { newValue in
//            source.wrappedValue = ((newValue?.isEmpty) != nil) ? nil : newValue
//        })
//    }
//}
// MARK: - Helpers
//private extension Binding where Value == String? {
//    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
//        self.init(
//            get: { source.wrappedValue ?? defaultValue },
//            set: { newValue in
//                if let text = newValue, !text.isEmpty {
//                    source.wrappedValue = text
//                } else {
//                    source.wrappedValue = nil
//                }
//            }
//        )
//    }
//}

// MARK: - Helpers
extension Binding where Value == String {
    /// 将 Optional<String> 转换为 Binding<String>
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in
                source.wrappedValue = newValue.isEmpty ? nil : newValue
            }
        )
    }
}


// MARK: - Preview
struct AddEventRecordView_Previews: PreviewProvider {
    static var previews: some View {
        AddEventRecordView(
            record: .init(id: "1", patientName: "张三", age: 28, gender: "男"),
            onBack: {},
            onSave: { _ in }
        )
    }
}

