//
//  CaseListView.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import SwiftUI

struct CaseListView: View {
    @State private var query: String = ""
    @State private var items: [CaseItem] = CaseRepository.samples

    var filtered: [CaseItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return items }
        let q = query.trimmingCharacters(in: .whitespaces)
        return items.filter { item in
            [item.patientName,
             item.relationship,
             item.chiefComplaint,
             item.diagnosis,
             item.status.rawValue
            ].joined(separator: " ")
                .localizedStandardContains(q)
            || item.symptoms.contains(where: { $0.localizedStandardContains(q) })
            || item.medications.contains(where: { $0.localizedStandardContains(q) })
        }
    }
    
    // Summary counts
    var totalCount: Int { items.count }
    var severeCount: Int { items.filter { $0.severity == .high }.count }
    var inTreatmentCount: Int { items.filter { $0.status == .inTreatment }.count }
    var favoriteCount: Int { items.filter { $0.isFavorite }.count }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SearchBar(text: $query)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                SummaryRow(total: totalCount,
                           severe: severeCount,
                           treating: inTreatmentCount,
                           favorites: favoriteCount)
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(filtered) { item in
                        CaseCard(item: binding(for: item))
                            .padding(.horizontal)
                    }
                    .animation(.spring(duration: 0.25), value: filtered)
                }
                .padding(.bottom, 16)

            }
        }
        .navigationTitle("病例管理")



    }
    
    private func binding(for item: CaseItem) -> Binding<CaseItem> {
        guard let idx = items.firstIndex(of: item) else {
            // 不应该发生；兜底返回只读
            return .constant(item)
        }
        return $items[idx]
    }
}
#Preview {
    CaseListView()
}
