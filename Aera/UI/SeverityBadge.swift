//
//  SeverityBadge.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import SwiftUI

struct SeverityBadge: View {
    let severity: Severity
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(severity.color).frame(width: 8, height: 8)
            Text(severity.title)
                .font(.caption).bold()
                .foregroundStyle(severity.color)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(severity.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct StatusTag: View {
    let status: CaseStatus
    var body: some View {
        CapsuleTag(text: status.rawValue, tint: status.tint.opacity(0.12), textColor: status.tint, icon: statusIcon)
    }
    private var statusIcon: String? {
        switch status {
        case .chronic:     return "leaf"
        case .inTreatment: return "bandage.fill"
        case .review:      return "clock.arrow.circlepath"
        case .cured:       return "checkmark.circle.fill"
        }
    }
}

struct CapsuleTag: View {
    var text: String
    var tint: Color = .secondary.opacity(0.12)
    var textColor: Color = .primary
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(textColor)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(tint)
        .clipShape(Capsule())
    }
}
