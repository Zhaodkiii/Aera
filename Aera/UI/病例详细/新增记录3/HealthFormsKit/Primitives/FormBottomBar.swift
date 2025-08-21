//
//  FormBottomBar.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/21.
//

import SwiftUI


// MARK: - Bottom Action Bar（固定底部操作条-公共视图）
public struct FormBottomBar: View {
    @Environment(\.colorScheme) private var scheme
    let isValid: Bool
    let cancelTitle: String?
    let saveTitle: String
    let saveSystemImage: String?
    let onCancel: () -> Void
    let onSave: () -> Void

    public init(
        isValid: Bool,
        cancelTitle: String?,
        saveTitle: String = "保存记录",
        saveSystemImage: String? = "check",
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.isValid = isValid
        self.cancelTitle = cancelTitle
        self.saveTitle = saveTitle
        self.saveSystemImage = saveSystemImage
        self.onCancel = onCancel
        self.onSave = onSave
    }

    public var body: some View {
        HStack {
           if let cancelTitle {
               Button(action: onCancel) { Text(cancelTitle) }
                   .buttonStyle(BorderButtonStyle())
            }
      

            Button(action: onSave) {
                if let sys = saveSystemImage {
                    Label(saveTitle, systemImage: sys).labelStyle(.titleAndIcon)
                } else {
                    Text(saveTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.6)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: DesignTokens.subtleShadow(scheme), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Overlay Modifier（将操作条吸底覆盖到任意视图上）
public struct FormBottomBarOverlay: ViewModifier {
    let isValid: Bool
    let cancelTitle: String?
    let saveTitle: String
    let saveSystemImage: String?
    let onCancel: () -> Void
    let onSave: () -> Void

    public func body(content: Content) -> some View {
        ZStack {
            content
            VStack { Spacer(); FormBottomBar(isValid: isValid, cancelTitle: cancelTitle, saveTitle: saveTitle, saveSystemImage: saveSystemImage, onCancel: onCancel, onSave: onSave) }
        }
    }
}

public extension View {
    /// 为任意页面追加一个吸底的操作条（取消/保存）。
    func formBottomBarOverlay(
        isValid: Bool,
        cancelTitle: String? = nil,
        saveTitle: String = "保存记录",
        saveSystemImage: String? = "check",
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) -> some View {
        modifier(FormBottomBarOverlay(isValid: isValid, cancelTitle: cancelTitle, saveTitle: saveTitle, saveSystemImage: saveSystemImage, onCancel: onCancel, onSave: onSave))
    }
}
