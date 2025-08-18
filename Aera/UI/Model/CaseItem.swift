//
//  CaseItem.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import Foundation
import SwiftUI


struct CaseItem: Identifiable, Hashable {
    let id: String
    var patientName: String
    var age: Int
    var gender: String               // "男"/"女"
    var relationship: String         // “爸爸”“妈妈”“本人”等
    var chiefComplaint: String
    var diagnosis: String
    var symptoms: [String]
    var severity: Severity
    var visitDate: Date
    var status: CaseStatus
    var medications: [String]
    var notes: String
    var isFavorite: Bool
}

enum Severity: String, Codable, CaseIterable {
    case low, medium, high
    
    var title: String {
        switch self {
        case .low: return "轻"
        case .medium: return "中"
        case .high: return "重"
        }
    }
    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
}

enum CaseStatus: String, Codable, CaseIterable {
    case chronic = "慢性管理"
    case inTreatment = "治疗中"
    case review = "复查中"
    case cured = "已治愈"
    
    var tint: Color {
        switch self {
        case .chronic:      return .gray
        case .inTreatment:  return .blue
        case .review:       return .teal
        case .cured:        return .green
        }
    }
}
