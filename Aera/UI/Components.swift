//
//  Components.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import SwiftUI


struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
            TextField("搜索患者、诊断或症状…", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SummaryRow: View {
    let total: Int
    let severe: Int
    let treating: Int
    let favorites: Int
    
    var body: some View {
        HStack(spacing: 14) {
            SummaryTile(title: "总病例", value: total.description)
            SummaryTile(title: "严重", value: severe.description)
            SummaryTile(title: "治疗中", value: treating.description)
            SummaryTile(title: "收藏", value: favorites.description)
        }
    }
}

struct SummaryTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3).bold()
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}


