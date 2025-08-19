//
//  ConfirmRecognizedCaseView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/20.
//

import SwiftUI

// MARK: - 数据模型（你可替换为自己的 CaseItem）
struct RecognizedCase {
    var confidence: Int
    var patient: Patient?
    var chiefComplaint: String
    var diagnosis: String
    var symptoms: [String]
    var firstSymptomDate: Date?
    var diagnosisDate: Date?
    var medications: [String]
    var attachments: [Attachment] = []
    var notes: String = ""
    
    struct Patient: Identifiable, Hashable {
        var id = UUID()
        var name: String
        var relation: String
        var age: Int
        var gender: String
        var caseCount: Int
    }
    struct Attachment: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var type: AttachmentType
        enum AttachmentType: String { case image = "图片", pdf = "PDF" }
    }
}

// MARK: - 确认页
struct ConfirmRecognizedCaseView: View {
    // 识别结果（从你的 OCR/解析流入）
    @State var form = RecognizedCase(
        confidence: 92,
        patient: .init(name: "李明华", relation: "妈妈", age: 58, gender: "女", caseCount: 1),
        chiefComplaint: "头晕伴恶心呕吐3天",
        diagnosis: "高血压（Essential Hypertension, ICD-10: I10）",
        symptoms: ["头晕","恶心","呕吐","心悸","乏力"],
        firstSymptomDate: ISO8601DateFormatter().date(from: "2024-07-15T00:00:00Z"),
        diagnosisDate: ISO8601DateFormatter().date(from: "2024-07-20T00:00:00Z"),
        medications: ["苯磺酸氨氯地平片","厄贝沙坦片"],
        attachments: [.init(name: "病例照片.jpg", type: .image)]
    )
    
    var onSave: (RecognizedCase) -> Void = { _ in } // 保存回调
    
    @Environment(\.dismiss) private var dismiss
    @State private var showPatientPicker = false
    
    @State private var allPatients: [PatientItem] = demoPatients // 你的数据源
    @State private var selectedPatient: PatientItem?

    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
//                    headerBarSpacer // 顶部吸附栏占位
                    
                    successBanner
                    
                    // 选择患者
                    
                    Card {
                        CardTitle(icon: "person", title: "选择患者", required: true)
                        if let p = form.patient {
                            SelectedPatientRow(patient: p) {
                                form.patient = nil
                            }
                        } else {
//                            Button {
//                                showPatientPicker = true
//                            } label: {
//                                HStack(spacing: 10) {
//                                    Image(systemName: "person.crop.circle.badge.plus")
//                                    Text("选择或新建患者")
//                                    Spacer()
//                                }
//                                .frame(height: 44)
//                                .padding(.horizontal, 12)
//                                .background(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.25)))
//                            }
//                            .buttonStyle(.plain)
//                            .popover(isPresented: $showPatientPicker, arrowEdge: .bottom) {
//                                PatientPickerPopover(
//                                    patients: allPatients,
//                                    onSelect: { p in
//                                        selectedPatient = p
//                                        showPatientPicker = false
//                                    },
//                                    onAddNew: {
//                                        // TODO: 跳转新建患者页
//                                        showPatientPicker = false
//                                    }
//                                )
//                                .frame(maxWidth: 420) // iPad/大屏弹出宽度
//                            }

                            
                            Button {
                                showPatientPicker = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text("选择或新建患者")
                                    Spacer()
                                }
                                .frame(height: 44)
                                .padding(.horizontal, 12)
                                .background(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.25)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // 病情信息
                    Card {
                        CardTitle(icon: "stethoscope", title: "病情信息")
                        VStack(spacing: 12) {
                            LabeledTextArea(title: "主诉 *", text: $form.chiefComplaint, minHeight: 80, placeholder: "描述主要症状和病史")
                            LabeledTextField(title: "诊断 *", text: $form.diagnosis, placeholder: "疾病诊断")
                            
                            // 症状标签
                            VStack(alignment: .leading, spacing: 6) {
                                Text("症状标签").font(.subheadline.weight(.medium))
                                TagEditor(tags: $form.symptoms,
                                          tint: .blue.opacity(0.12),
                                          fg: .blue,
                                          placeholder: "输入症状后按回车添加")
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // 时间记录
                    Card {
                        CardTitle(icon: "calendar", title: "时间记录")
                        VStack(spacing: 12) {
                            DateRow(title: "首次出现日期", selection: Binding($form.firstSymptomDate, replacingNilWith: Date()))
                            DateRow(title: "确诊日期", selection: Binding($form.diagnosisDate, replacingNilWith: Date()))
                        }
                    }
                    
                    // 用药信息
                    Card {
                        CardTitle(icon: "pill", title: "用药信息")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("当前用药").font(.subheadline.weight(.medium))
                            TagEditor(tags: $form.medications,
                                      tint: .green.opacity(0.12),
                                      fg: .green,
                                      placeholder: "输入药物名称后按回车添加")
                        }
                    }
                    
                    // 附件
                    if !form.attachments.isEmpty {
                        Card {
                            CardTitle(icon: "paperclip", title: "附件")
                            VStack(spacing: 6) {
                                ForEach(form.attachments) { a in
                                    AttachmentRow(att: a)
                                }
                            }.padding(.top, 4)
                        }
                    }
                    
                    // 备注
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注").font(.subheadline.weight(.medium))
                            TextArea(text: $form.notes, minHeight: 64, placeholder: "其他备注信息")
                        }
                    }
                    
                    Color.clear.frame(height: 84) // 给底部按钮留出滚动空间
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            // 底部提交按钮
            bottomBar
        }
//        .overlay(alignment: .top) { stickyHeader }
        .sheet(isPresented: $showPatientPicker) {
            // 这里放你的选择患者页面；Demo 里直接选一个
            DemoPatientPicker { selected in
                form.patient = selected
            }
        }
        .background(Color(.systemBackground))
        
        .navigationTitle("新增病例")
    }
    
    // MARK: - 顶部吸附栏
//    private var stickyHeader: some View {
//        VStack(spacing: 0) {
//            HStack {
//                Button {
//                    dismiss()
//                } label: {
//                    Image(systemName: "arrow.left")
//                        .font(.system(size: 18, weight: .semibold))
//                }
//                .buttonStyle(.plain)
//                Text("新增病例").font(.headline)
//                Spacer().frame(width: 24) // 对齐
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 10)
//            .background(.background)
//            Divider()
//        }
//        .background(.background)
//    }
//    private var headerBarSpacer: some View {
//        Color.clear.frame(height: 44) // 与 stickyHeader 高度匹配
//    }
    
    // MARK: - 成功提示
    private var successBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green).font(.title3)
            Text("识别成功").foregroundStyle(.green)
            Spacer()
            Badge(text: "置信度 \(form.confidence)%", tintBG: .green.opacity(0.15), tintFG: .green)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.35)))
    }
    
    // MARK: - 底部按钮
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                dismiss()

                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSave(form)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("✅ 保存病例")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .frame(maxWidth: .infinity)
        .background(.background)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - 子视图

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct CardTitle: View {
    var icon: String
    var title: String
    var required: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title).font(.subheadline.weight(.semibold))
            if required { Badge(text: "必填") }
            Spacer()
        }
    }
}

private struct SelectedPatientRow: View {
    var patient: RecognizedCase.Patient
    var onClear: () -> Void
    var body: some View {
        HStack {
            // 头像
            ZStack {
                Circle().fill(Color.blue.opacity(0.12))
                Text(String(patient.name.prefix(2)))
                    .foregroundStyle(.blue)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(patient.name).font(.body.weight(.semibold))
                    Badge(text: patient.relation)
                }
                Text("\(patient.age)岁 · \(patient.gender) · \(patient.caseCount)条病例")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)
            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.7)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.25)))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.35)))
    }
}

private struct LabeledTextArea: View {
    var title: String
    @Binding var text: String
    var minHeight: CGFloat = 80
    var placeholder: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            TextArea(text: $text, minHeight: minHeight, placeholder: placeholder)
        }
    }
}

private struct LabeledTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12).frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.25)))
        }
    }
}

private struct TextArea: View {
    @Binding var text: String
    var minHeight: CGFloat = 64
    var placeholder: String = ""
    @State private var dynamicHeight: CGFloat = 0
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder).foregroundStyle(.secondary).padding(.horizontal, 14).padding(.vertical, 10)
            }
            TextEditor(text: $text)
                .frame(minHeight: max(minHeight, dynamicHeight))
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.25)))
                .onChange(of: text) { _ in
                    // 粗略自适应（无需精确）
                    dynamicHeight = CGFloat(max(0, text.count/30)) * 18
                }
        }
    }
}

private struct TagEditor: View {
    @Binding var tags: [String]
    var tint: Color = .orange.opacity(0.12)
    var fg: Color = .orange
    var placeholder: String = "输入后回车添加"
    @State private var input = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8, runSpacing: 8) {
                ForEach(Array(tags.enumerated()), id: \.offset) { idx, t in
                    HStack(spacing: 4) {
                        Text(t).font(.caption)
                        Button {
                            tags.remove(at: idx)
                        } label: {
                            Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.6)))
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(tint))
                    .foregroundStyle(fg)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(fg.opacity(0.25)))
                }
            }
            
            // 输入框
            TextField(placeholder, text: $input)
                .onSubmit { addTag() }
                .submitLabel(.done)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12).frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.25)))
        }
    }
    private func addTag() {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        if !tags.contains(t) { tags.append(t) }
        input = ""
    }
}

//private struct DateRow: View {
//    var title: String
//    @Binding var selection: Date
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            Text(title).font(.subheadline.weight(.medium))
//            DatePicker("", selection: $selection, displayedComponents: .date)
//                .datePickerStyle(.compact)
//                .labelsHidden()
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal, 12).frame(height: 40)
//                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
//                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.25)))
//        }
//    }
//}
struct DateRow: View {
    var title: String
    @Binding var selection: Date?   // 支持可选
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            DatePicker(
                "",
                selection: Binding(
                    get: { selection ?? Date() },
                    set: { selection = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.25)))
        }
    }
}
private struct AttachmentRow: View {
    var att: RecognizedCase.Attachment
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.12))
                Image(systemName: att.type == .pdf ? "doc.richtext" : "photo")
                    .foregroundStyle(.blue)
            }
            .frame(width: 32, height: 32)
            Text(att.name).font(.subheadline)
            Spacer()
            Badge(text: att.type.rawValue)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }
}

private struct Badge: View {
    var text: String
    var tintBG: Color = .gray.opacity(0.12)
    var tintFG: Color = .primary
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 7).fill(tintBG))
            .foregroundStyle(tintFG)
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(tintFG.opacity(0.25)))
    }
}

// MARK: - Demo 患者选择器（替换为你的真实页面）
private struct DemoPatientPicker: View {
    var onPick: (RecognizedCase.Patient) -> Void
    @Environment(\.dismiss) private var dismiss
    let candidates: [RecognizedCase.Patient] = [
        .init(name: "李明华", relation: "妈妈", age: 58, gender: "女", caseCount: 1),
        .init(name: "王建国", relation: "爸爸", age: 65, gender: "男", caseCount: 3),
        .init(name: "张小明", relation: "本人", age: 28, gender: "男", caseCount: 2),
    ]
    var body: some View {
        NavigationStack {
            List(candidates, id: \.id) { p in
                Button {
                    onPick(p); dismiss()
                } label: {
                    HStack {
                        Text(p.name)
                        Spacer()
                        Text(p.relation).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("选择患者")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("关闭") { dismiss() } }
            }
        }
    }
}

// MARK: - 便捷 Binding（支持可选日期）
extension Binding where Value == Date? {
    init(_ source: Binding<Date?>, replacingNilWith fallback: Date) {
        self.init(
            get: { source.wrappedValue ?? fallback },
            set: { new in source.wrappedValue = new }
        )
    }
}

// MARK: - 预览
struct ConfirmRecognizedCaseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ConfirmRecognizedCaseView() }
            .environment(\.locale, .init(identifier: "zh-Hans"))
    }
}

// MARK: - 数据结构
struct PatientItem: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var relation: String  // 本人/爸爸/妈妈/妹妹...
    var age: Int
    var gender: String    // 男/女
    var lastVisit: Date?
    
    // 头像首字
    var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(2))
    }
}

// MARK: - Popover 命令面板
struct PatientPickerPopover: View {
    var patients: [PatientItem]
    var onSelect: (PatientItem) -> Void
    var onAddNew: () -> Void
    
    @State private var query: String = ""
    @State private var scrollID: UUID? = nil
    
    private var filtered: [PatientItem] {
        guard !query.isEmpty else { return patients }
        return patients.filter { p in
            p.name.localizedCaseInsensitiveContains(query)
            || p.relation.localizedCaseInsensitiveContains(query)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("搜索患者姓名或关系...", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .frame(height: 44)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial)
            .overlay(Divider(), alignment: .bottom)
            
            // 列表
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filtered) { p in
                        PatientRow(patient: p) {
                            onSelect(p)
                        }
                        .id(p.id)
                    }
                    
                    // 无结果占位 + 新建入口
                    if filtered.isEmpty {
                        VStack(spacing: 10) {
                            Text("没有找到结果").font(.subheadline).foregroundStyle(.secondary)
                            Button {
                                onAddNew()
                            } label: {
                                Label("新建患者“\(query)”", systemImage: "plus.circle.fill")
                                    .labelStyle(.titleAndIcon)
                                    .padding(.horizontal, 12)
                                    .frame(height: 36)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 16)
                    }
                }
                .padding(8)
                .frame(maxHeight: 320) // 与 HTML 的 max-h-64 类似
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .padding(8)
    }
}

// MARK: - 单行
private struct PatientRow: View {
    let patient: PatientItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // 头像
                ZStack {
                    Circle().fill(Color.gray.opacity(0.12))
                    Text(patient.initials)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 32, height: 32)
                
                // 文本
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(patient.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Badge(text: patient.relation)
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .opacity(0) // 常态透明，hover/选中时可改样式
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.12))
                )
        )
    }
    
    private var subtitle: String {
        let ageSex = "\(patient.age)岁 · \(patient.gender)"
        if let d = patient.lastVisit {
            return ageSex + " · 上次就诊 " + DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none)
        } else {
            return ageSex
        }
    }
}

// MARK: - 小徽章
//private struct Badge: View {
//    var text: String
//    var body: some View {
//        Text(text)
//            .font(.caption.weight(.medium))
//            .padding(.horizontal, 6).padding(.vertical, 2)
//            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.12)))
//            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.25)))
//            .foregroundStyle(.primary)
//    }
//}

// MARK: - Demo 数据
let demoPatients: [PatientItem] = [
    .init(name: "李明华", relation: "妈妈", age: 58, gender: "女", lastVisit: makeDate("2024-08-10")),
    .init(name: "张小明", relation: "本人", age: 28, gender: "男", lastVisit: makeDate("2024-08-05")),
    .init(name: "王建国", relation: "爸爸", age: 65, gender: "男", lastVisit: makeDate("2024-07-28")),
    .init(name: "刘小红", relation: "妹妹", age: 35, gender: "女", lastVisit: makeDate("2024-08-12"))
]
func makeDate(_ s: String) -> Date? {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "zh_CN")
    return f.date(from: s)
}
