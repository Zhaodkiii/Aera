//
//  CDNewFormView.swift
//  Aera
//
//  Created by 話 on 2025/8/21.
//
import SwiftUI
import _PhotosUI_SwiftUI

// MARK: - 表单页
struct CDNewFormView: View {
    let kind: CDEventKind
    var onSave: (CDEventItem) -> Void

    @StateObject private var vm: CDNewFormModel
    @Environment(\.dismiss) private var dismiss
    @State private var showFileImporter = false

    init(kind: CDEventKind, onSave: @escaping (CDEventItem) -> Void) {
        self.kind = kind
        self.onSave = onSave
        _vm = StateObject(wrappedValue: CDNewFormModel(kind: kind))
    }

    var body: some View {
        Form {
            Section("基础信息") {
                DatePicker("日期", selection: $vm.date, displayedComponents: .date)
                Toggle("填写时间", isOn: $vm.hasTime)
                if vm.hasTime {
                    DatePicker("时间", selection: $vm.time, displayedComponents: .hourAndMinute)
                }
                TextField("标题（必填）", text: $vm.title)
                TextField("记录人", text: $vm.author)
            }

            Section("内容") {
                TextEditor(text: $vm.detail)
                    .frame(minHeight: 120)
            }

            // 严重度：临床/指标（依据类型展示其一或都可选）
            Section("严重度") {
                Picker("临床严重度", selection: Binding(get: {
                    vm.clinical ?? .轻度
                }, set: { vm.clinical = $0 })) {
                    Text("未选择").tag(CDClinicalSeverity?.none)
                    ForEach(CDClinicalSeverity.allCases, id: \.self) { v in
                        Text(v.rawValue).tag(Optional(v))
                    }
                }
                .pickerStyle(.menu)

                if kind == .测量 || kind == .检查 {
                    Picker("指标异常度", selection: Binding(get: {
                        vm.signal ?? .正常
                    }, set: { vm.signal = $0 })) {
                        Text("未选择").tag(CDSignalSeverity?.none)
                        ForEach(CDSignalSeverity.allCases, id: \.self) { v in
                            Text(v.rawValue).tag(Optional(v))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // 附件
            Section("附件") {
                PhotosPicker(selection: $vm.pickedPhotos, maxSelectionCount: 4, matching: .images) {
                    Label("从相册选择照片", systemImage: "photo.on.rectangle.angled")
                }
                Button {
                    showFileImporter = true
                } label: {
                    Label("从文件导入（PDF/报告等）", systemImage: "folder.badge.plus")
                }

                if !vm.attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(vm.attachments) { a in
                                HStack(spacing: 6) {
                                    Image(systemName: a.resolvedIcon).font(.caption)
                                    Text(a.title).lineLimit(1)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Capsule().fill(Color.blue.opacity(0.08)))
                                .overlay(Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1))
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(kind.rawValue + "记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存", action: cdNewHandleSave)
                    .disabled(vm.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onChange(of: vm.pickedPhotos) { _, _ in cdNewIngestPickedPhotos() }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: true) { result in
            cdNewHandleFileImport(result)
        }
    }

    // MARK: - 事件：保存（唯一命名）
    private func cdNewHandleSave() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"

        let item = CDEventItem(
            kind: kind,
            date: df.string(from: vm.date),
            time: vm.hasTime ? tf.string(from: vm.time) : nil,
            title: vm.title.isEmpty ? kind.rawValue : vm.title,
            detail: vm.detail,
            attachments: vm.attachments,
            author: vm.author.isEmpty ? nil : vm.author,
            clinicalSeverity: vm.clinical,
            signalSeverity: vm.signal
        )
        onSave(item)
        dismiss()
    }

    // MARK: - 事件：相册选择导入（唯一命名）
    private func cdNewIngestPickedPhotos() {
        Task { @MainActor in
            guard !vm.pickedPhotos.isEmpty else { return }
            for (idx, _) in vm.pickedPhotos.enumerated() {
                // 这里只做占位生成附件名；实际可取 Asset 名称
                let name = "照片\(idx + 1).jpg"
                vm.attachments.append(.init(title: name, iconName: "photo", extHint: "jpg"))
            }
            vm.pickedPhotos.removeAll()
        }
    }

    // MARK: - 事件：文件导入（唯一命名）
    private func cdNewHandleFileImport(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result {
            for url in urls {
                vm.attachments.append(.init(title: url.lastPathComponent,
                                            iconName: nil,
                                            extHint: url.pathExtension))
            }
        }
    }
}
