//
//  Repository.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/19.
//

import Foundation
import SwiftUI
// MARK: - Repository (Mock Data)

struct CaseRepository {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    static var samples: [CaseItem] = [
        .init(
            id: "1",
            patientName: "李明华",
            age: 58,
            gender: "女",
            relationship: "妈妈",
            chiefComplaint: "头晕伴恶心呕吐3天",
            diagnosis: "高血压、颈椎病",
            symptoms: ["头晕", "恶心", "呕吐", "颈部僵硬", "视力模糊"],
            severity: .medium,
            visitDate: formatter.date(from: "2024-08-10")!,
            status: .inTreatment,
            medications: ["苯磺酸氨氯地平片", "颈复康颗粒"],
            notes: "血压控制良好，建议继续用药",
            isFavorite: true
        ),
        .init(
            id: "2",
            patientName: "张小明",
            age: 28,
            gender: "男",
            relationship: "本人",
            chiefComplaint: "反复眩晕发作2周",
            diagnosis: "良性阵发性位置性眩晕（耳石症）",
            symptoms: ["眩晕", "恶心", "出汗", "头重脚轻"],
            severity: .low,
            visitDate: formatter.date(from: "2024-08-05")!,
            status: .review,
            medications: ["倍他司汀片"],
            notes: "症状明显改善，继续复位治疗",
            isFavorite: false
        ),
        .init(
            id: "3",
            patientName: "王建国",
            age: 65,
            gender: "男",
            relationship: "爸爸",
            chiefComplaint: "胸闷气短伴心悸1月",
            diagnosis: "冠心病、心房颤动",
            symptoms: ["胸闷", "气短", "心悸", "乏力", "下肢水肿"],
            severity: .high,
            visitDate: formatter.date(from: "2024-07-28")!,
            status: .chronic,
            medications: ["阿司匹林", "美托洛尔", "华法林"],
            notes: "需要定期监测凝血功能和心电图",
            isFavorite: true
        ),
        .init(
            id: "4",
            patientName: "刘小红",
            age: 35,
            gender: "女",
            relationship: "妹妹",
            chiefComplaint: "偏头痛发作",
            diagnosis: "偏头痛",
            symptoms: ["头痛", "恶心", "畏光", "畏声"],
            severity: .medium,
            visitDate: formatter.date(from: "2024-08-12")!,
            status: .cured,
            medications: ["舒马普坦"],
            notes: "急性期已过，注意避免诱发因素",
            isFavorite: false
        )
    ]
}
