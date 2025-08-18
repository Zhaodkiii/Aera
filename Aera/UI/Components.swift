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

struct CaseCard: View {
    @Binding var item: CaseItem
    
    private var dateText: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: item.visitDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.patientName)
                            .font(.headline).bold()
                        Text("\(item.age)岁·\(item.gender)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        CapsuleTag(text: item.relationship, tint: .pink.opacity(0.9), icon: "person.2.fill")
                    }
                    
                    HStack(spacing: 8) {
                        SeverityBadge(severity: item.severity)
                        StatusTag(status: item.status)
                    }
                }
                Spacer()
                Button {
                    item.isFavorite.toggle()
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(item.isFavorite ? .yellow : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            // 主诉
            HStack(alignment: .top, spacing: 8) {
                Label("主诉", systemImage: "exclamationmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                Text(item.chiefComplaint)
                    .font(.subheadline)
            }
            
            // 诊断
            VStack(alignment: .leading, spacing: 6) {
                Text("诊断")
                    .font(.subheadline).bold()
                Text(item.diagnosis)
                    .font(.body.weight(.semibold))
            }
            
            // 症状标签
            if !item.symptoms.isEmpty {
                FlowLayout(spacing: 8, runSpacing: 8) {
                    ForEach(item.symptoms, id: \.self) { s in
                        CapsuleTag(text: s, tint: .orange.opacity(0.15), textColor: .orange)
                    }
                }
            }
            
            // 用药标签
            if !item.medications.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "pills.fill")
                        Text("用药")
                    }
                    .font(.subheadline.weight(.semibold))
                    
                    FlowLayout(spacing: 8, runSpacing: 8) {
                        ForEach(item.medications, id: \.self) { m in
                            CapsuleTag(text: m, tint: Color.blue.opacity(0.12), textColor: .blue)
                        }
                    }
                }
            }
            
            // 备注
            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            
            // 底部日期
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(dateText)
                Spacer()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        )
    }
}
