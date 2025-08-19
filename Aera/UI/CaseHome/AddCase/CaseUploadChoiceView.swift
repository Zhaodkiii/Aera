//
//  CaseUploadChoiceView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation


// MARK: - 可配置模式
enum UploadMode {
    case caseDocument   // 医院病例/检查单
    case checkupReport  // 体检报告
    
    var accent: Color {
        switch self {
        case .caseDocument: return .blue
        case .checkupReport: return .green
        }
    }
    var iconSystemName: String {
        switch self {
        case .caseDocument: return "square.and.arrow.up"
        case .checkupReport: return "waveform.path.ecg"
        }
    }
    var title: String {
        switch self {
        case .caseDocument: return "🏥 上传医院病例/检查单"
        case .checkupReport: return "🩺 上传体检报告"
        }
    }
    var subtitle: String {
        switch self {
        case .caseDocument: return "支持自动识别患者信息、诊断和用药"
        case .checkupReport: return "支持自动识别体检项目、检查结果和异常指标"
        }
    }
    var tips: [String] {
        switch self {
        case .caseDocument:
            return ["✨ 支持识别：患者信息、诊断、症状、用药",
                    "📋 支持格式：图片(JPG/PNG/HEIC)、PDF 文档"]
        case .checkupReport:
            return ["✨ 支持识别：体检项目、检查结果、异常指标",
                    "📋 支持格式：图片(JPG/PNG/HEIC)、PDF 文档"]
        }
    }
}

// MARK: - 通用上传选择页（支持两种模式）
struct CaseUploadChoiceView: View {
    var mode: UploadMode = .caseDocument

    /// 最大图片选择数
    var maxSelectionCount: Int = 20
    /// 是否允许选择 PDF（两种模式默认都允许，如需只允许图片可传 false）
    var allowPDF: Bool
    
    /// 选择完成回调：返回图片(UIImage)数组与文档(URL)数组（二者有其一）
    var onPicked: (_ images: [UIImage], _ documents: [URL]) -> Void = { _, _ in }
    
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showDocPicker = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var cameraDeniedAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 虚线卡片
                VStack(spacing: 18) {
                    // 顶部图标与标题
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(mode.accent.opacity(0.12)).frame(width: 64, height: 64)
                            Image(systemName: mode.iconSystemName)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(mode.accent)
                        }
                        Text(mode.title).font(.headline)
                        Text(mode.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 入口按钮
                    VStack(spacing: 10) {
                        ActionRow(icon: "camera", title: "📷 拍照") {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            requestCameraAndPresent()
                        }
                        ActionRow(icon: "photo.on.rectangle", title: "🖼 从相册选择") {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showPhotoPicker = true
                        }
                        if allowPDF {
                            ActionRow(icon: "doc.text", title: "📄 上传 PDF") {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showDocPicker = true
                            }
                        }
                    }
                    
                    // 说明
                    VStack(spacing: 2) {
                        ForEach(mode.tips, id: \.self) { t in
                            Text(t)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                        .foregroundStyle(Color.gray.opacity(0.4))
                )
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .navigationTitle(mode == .caseDocument ? "选择病例/检查单" : "选择体检报告")
        // 相册
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $photoItems,
                      maxSelectionCount: maxSelectionCount,
                      matching: .images)
        .onChange(of: photoItems) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task {
                var images: [UIImage] = []
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        images.append(img)
                    }
                }
                onPicked(images, [])
                photoItems.removeAll()
            }
        }
        // 相机
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                showCamera = false
                if let image { onPicked([image], []) }
            }
        }
        .alert("无法使用相机", isPresented: $cameraDeniedAlert) {
            Button("好") {}
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("请在“设置 > 隐私与安全性 > 相机”中允许访问。")
        }
        // 文档
        .sheet(isPresented: $showDocPicker) {
            DocPicker(allowed: [.pdf]) { urls in
                onPicked([], urls)
            }
        }
    }
    
    // MARK: - 权限
    private func requestCameraAndPresent() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { granted ? (showCamera = true) : (cameraDeniedAlert = true) }
            }
        case .denied, .restricted:
            cameraDeniedAlert = true
        @unknown default:
            cameraDeniedAlert = true
        }
    }
}

// MARK: - 行按钮（统一样式）
private struct ActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .frame(height: 48)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .hoverEffect(.highlight)
    }
}

// MARK: - 相机封装
struct CameraView: UIViewControllerRepresentable {
    var onShot: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onShot: onShot) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = context.coordinator
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onShot: (UIImage?) -> Void
        init(onShot: @escaping (UIImage?) -> Void) { self.onShot = onShot }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            onShot(image)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onShot(nil) }
    }
}

// MARK: - 文档选择器（PDF）
struct DocPicker: UIViewControllerRepresentable {
    let allowed: [UTType]
    var onPick: ([URL]) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowed, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { onPick(urls) }
    }
}

//
//// MARK: - 入口页
//struct CaseUploadChoiceView: View {
//    /// 选择完成回调：返回图片(UIImage)数组与文档(URL)数组（二者有其一）
//    var onPicked: (_ images: [UIImage], _ documents: [URL]) -> Void = { _, _ in }
//    
//    @State private var showCamera = false
//    @State private var showPhotoPicker = false
//    @State private var showDocPicker = false
//    @State private var photoItems: [PhotosPickerItem] = []
//    @State private var cameraImage: UIImage? = nil
//    @State private var isCheckingCameraAuth = false
//    @State private var cameraDeniedAlert = false
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 16) {
//                // 虚线卡片
//                VStack(spacing: 18) {
//                    // 顶部图标与标题
//                    VStack(spacing: 8) {
//                        ZStack {
//                            Circle().fill(Color.blue.opacity(0.12)).frame(width: 64, height: 64)
//                            Image(systemName: "square.and.arrow.up")
//                                .font(.system(size: 28, weight: .semibold))
//                                .foregroundStyle(.blue)
//                        }
//                        Text("🏥 上传医院病例/检查单")
//                            .font(.headline)
//                        Text("支持自动识别患者信息、诊断和用药")
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                    }
//                    
//                    // 三个按钮
//                    VStack(spacing: 10) {
//                        ActionRow(icon: "camera", title: "📷 拍照") {
//                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                            requestCameraAndPresent()
//                        }
//                        ActionRow(icon: "photo.on.rectangle", title: "🖼 从相册选择") {
//                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                            showPhotoPicker = true
//                        }
//                        ActionRow(icon: "doc.text", title: "📄 上传 PDF") {
//                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                            showDocPicker = true
//                        }
//                    }
//                    
//                    // 说明
//                    VStack(spacing: 2) {
//                        Text("✨ 支持识别：患者信息、诊断、症状、用药")
//                        Text("📋 支持格式：图片(JPG/PNG/HEIC)、PDF文档")
//                    }
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                }
//                .padding(16)
//                .background(
//                    RoundedRectangle(cornerRadius: 16, style: .continuous)
//                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
//                        .foregroundStyle(Color.gray.opacity(0.4))
//                )
//                .padding(.horizontal, 16)
//            }
//            .padding(.vertical, 12)
//        }
//        .navigationTitle("选择病例/检查单")
//        // 相册
//        .photosPicker(isPresented: $showPhotoPicker,
//                      selection: $photoItems,
//                      maxSelectionCount: 20,
//                      matching: .images)
//        .onChange(of: photoItems) { _, newValue in
//            guard !newValue.isEmpty else { return }
//            Task {
//                var images: [UIImage] = []
//                for item in newValue {
//                    if let data = try? await item.loadTransferable(type: Data.self),
//                       let img = UIImage(data: data) {
//                        images.append(img)
//                    }
//                }
//                onPicked(images, [])
//                photoItems.removeAll()
//            }
//        }
//        // 相机
//        .sheet(isPresented: $showCamera) {
//            CameraView { image in
//                showCamera = false
//                if let image { onPicked([image], []) }
//            }
//        }
//        .alert("无法使用相机", isPresented: $cameraDeniedAlert) {
//            Button("好") {}
//            Button("去设置", role: .none) {
//                if let url = URL(string: UIApplication.openSettingsURLString) {
//                    UIApplication.shared.open(url)
//                }
//            }
//        } message: {
//            Text("请在“设置 > 隐私与安全性 > 相机”中允许访问。")
//        }
//        // 文档
//        .sheet(isPresented: $showDocPicker) {
//            DocPicker(allowed: [.pdf]) { urls in
//                onPicked([], urls)
//            }
//        }
//    }
//    
//    // MARK: - 权限与相机
//    private func requestCameraAndPresent() {
//        isCheckingCameraAuth = true
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized:
//            showCamera = true
//        case .notDetermined:
//            AVCaptureDevice.requestAccess(for: .video) { granted in
//                DispatchQueue.main.async {
//                    granted ? (showCamera = true) : (cameraDeniedAlert = true)
//                }
//            }
//        case .denied, .restricted:
//            cameraDeniedAlert = true
//        @unknown default:
//            cameraDeniedAlert = true
//        }
//        isCheckingCameraAuth = false
//    }
//}
//
//// MARK: - 行按钮
//private struct ActionRow: View {
//    let icon: String
//    let title: String
//    let action: () -> Void
//    var body: some View {
//        Button(action: action) {
//            HStack(spacing: 10) {
//                Image(systemName: icon)
//                Text(title)
//                Spacer()
//            }
//            .frame(height: 48)
//            .padding(.horizontal, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .fill(Color(.systemBackground))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 12, style: .continuous)
//                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
//                    )
//            )
//        }
//        .foregroundStyle(.primary)
//        .buttonStyle(.plain)
//        .contentShape(Rectangle())
//        .hoverEffect(.highlight)
//    }
//}
//
//// MARK: - 相机封装
//struct CameraView: UIViewControllerRepresentable {
//    var onShot: (UIImage?) -> Void
//    
//    func makeCoordinator() -> Coordinator { Coordinator(onShot: onShot) }
//    
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let vc = UIImagePickerController()
//        vc.sourceType = .camera
//        vc.delegate = context.coordinator
//        vc.modalPresentationStyle = .fullScreen
//        return vc
//    }
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//    
//    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let onShot: (UIImage?) -> Void
//        init(onShot: @escaping (UIImage?) -> Void) { self.onShot = onShot }
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
//            onShot(image)
//        }
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            onShot(nil)
//        }
//    }
//}
//
//// MARK: - 文档选择器（PDF）
//struct DocPicker: UIViewControllerRepresentable {
//    let allowed: [UTType]
//    var onPick: ([URL]) -> Void
//    
//    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
//    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
//        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowed, asCopy: true)
//        picker.allowsMultipleSelection = true
//        picker.delegate = context.coordinator
//        return picker
//    }
//    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
//    
//    final class Coordinator: NSObject, UIDocumentPickerDelegate {
//        let onPick: ([URL]) -> Void
//        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }
//        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//            onPick(urls)
//        }
//    }
//}
