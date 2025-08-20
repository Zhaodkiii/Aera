//
//  ExamItem.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/20.
//

import SwiftUI


// MARK: - 1) 升级本地模型

/// 原来只有 normal/low/medium/high；为适配 JSON，补充 abnormal
enum ExamAbnormalStatus: String, Codable, CaseIterable {
    case normal
    case low
    case medium
    case high
    case abnormal       // 非方向性异常（如影像“阳性/阴性”）
}

enum ExamSeverity: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low:
            return .yellow      // 低风险 → 绿色
        case .medium:
            return .orange     // 中风险 → 橙色
        case .high:
            return .red        // 高风险 → 红色
        }
    }
}
struct ExamItem: Identifiable, Codable {
    let id: String
    let category: String
    let subcategory: String
    let itemName: String
    let result: String
    let unit: String?
    let referenceRange: String?
    let status: ExamAbnormalStatus
    let description: String?
    let recommendation: String?
    let severity: ExamSeverity?
}

struct ExamReportMeta {
    var patientName: String
    var relation: String
    var age: Int
    var gender: String
    var scene: String
    var examDate: Date
    var hospital: String
    var confidence: Int    // 0~100
}

struct ExamSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    var items: [ExamItem]
    var badgeText: String { "\(items.count)项" }
}

struct ExamReportResult {
    var meta: ExamReportMeta
    var highRisk: [ExamItem]
    var midRisk: [ExamItem]
    var lowRisk: [ExamItem]
    var normalCount: Int
    var abnormalCount: Int
    var totalCount: Int { normalCount + abnormalCount }
    var sections: [ExamSection]
    var suggestions: [String]
}

// MARK: - 2) DTO（对齐你给的 JSON 字段）

// MARK: - API DTO
struct ApiExamReport: Decodable {
    let patientName: String
    let age: Int
    let gender: String
    let relationship: String
    let examType: String
    let examDate: String
    let institution: String
    let abnormalCount: Int
    let totalItems: Int
    let normalItems: Int
    let abnormalItems: [ApiAbnormalItem]
    let confidence: Double
}

struct ApiAbnormalItem: Identifiable, Codable, Hashable {
    let id: String
    let category: String
    let subcategory: String
    let itemName: String
    let result: String
    let unit: String?
    let referenceRange: String?
    let status: String          // "high" | "abnormal" | ...
    let description: String?
    let recommendation: String?
    let severity: String?       // "low" | "medium" | "high"
}


enum ExamStatus: String,Codable, Hashable {
    case 正常
    case 异常
}

enum Severitya: String,Codable, Hashable {
    case low
    case medium
    case high
    case none
}

struct ExamItemaaa: Identifiable, Codable, Hashable {
    let id: String
    let category: String
//    let subcategory: String
    let conclusion: String
    let itemName: String
    let result: String
    let riskLevel: String?
    let unit: String?
//    let referenceRange: String?
    let status: ExamStatus
//    let description: String?
    let recommendation: String?
//    let severity: Severitya
}


let apiadsss: String = """
[
{
    "id": "1",
    "category": "一般检查",
    "itemName": "身高",
    "result": "149.2 cm",
    "conclusion": "正常",
    "recommendation": "正常，无需特殊处理。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "2",
    "category": "一般检查",
    "itemName": "体重",
    "result": "58.4 kg",
    "conclusion": "超重",
    "recommendation": "建议节制饮食，适量运动，控制体重。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "3",
    "category": "一般检查",
    "itemName": "BMI",
    "result": "26.23 kg/㎡",
    "conclusion": "超重",
    "recommendation": "超重，控制饮食，增加运动，避免肥胖相关疾病。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "4",
    "category": "一般检查",
    "itemName": "收缩压",
    "result": "130 mmHg",
    "conclusion": "正常(服药控制)",
    "recommendation": "血压控制良好，继续规律监测和服药。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "5",
    "category": "一般检查",
    "itemName": "舒张压",
    "result": "68 mmHg",
    "conclusion": "正常",
    "recommendation": "正常，维持健康生活方式。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "6",
    "category": "一般检查",
    "itemName": "腰围",
    "result": "80 cm",
    "conclusion": "正常",
    "recommendation": "正常，注意维持健康饮食和运动。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "7",
    "category": "一般检查",
    "itemName": "臀围",
    "result": "95 cm",
    "conclusion": "正常",
    "recommendation": "正常，注意维持健康饮食和运动。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "8",
    "category": "一般检查",
    "itemName": "腰臀比",
    "result": "0.84",
    "conclusion": "正常",
    "recommendation": "正常，继续保持健康。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "9",
    "category": "内科",
    "itemName": "心率",
    "result": "66 次/分",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "10",
    "category": "内科",
    "itemName": "心律",
    "result": "律齐",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "11",
    "category": "内科",
    "itemName": "心音",
    "result": "正常",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "12",
    "category": "内科",
    "itemName": "心脏杂音",
    "result": "无",
    "conclusion": "正常",
    "recommendation": "无异常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "13",
    "category": "内科",
    "itemName": "肝脏",
    "result": "未及",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "14",
    "category": "内科",
    "itemName": "胆囊",
    "result": "区无压痛",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "15",
    "category": "内科",
    "itemName": "脾脏",
    "result": "未及",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "16",
    "category": "内科",
    "itemName": "肾脏",
    "result": "无叩击痛",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "17",
    "category": "内科",
    "itemName": "神经系统",
    "result": "生理反射正常",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "18",
    "category": "内科",
    "itemName": "既往史",
    "result": "高血压",
    "conclusion": "异常",
    "recommendation": "高血压，需规律服药，低盐饮食，监测血压。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "19",
    "category": "口腔科",
    "itemName": "牙齿",
    "result": "牙结石",
    "conclusion": "异常",
    "recommendation": "牙结石，建议到医院口腔科超声波洁治。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "20",
    "category": "口腔科",
    "itemName": "口腔黏膜/舌/腭/颞颌关节",
    "result": "未见异常",
    "conclusion": "正常",
    "recommendation": "未见异常，无需特殊处理。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "21",
    "category": "妇科",
    "itemName": "外阴/阴道/宫颈/宫体/附件",
    "result": "未见异常",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "22",
    "category": "妇科",
    "itemName": "分泌物",
    "result": "未见异常",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "23",
    "category": "妇科",
    "itemName": "月经史",
    "result": "绝经",
    "conclusion": "正常",
    "recommendation": "绝经，无需特殊处理。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "24",
    "category": "血常规",
    "itemName": "白细胞计数",
    "result": "5.0×10^9/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "25",
    "category": "血常规",
    "itemName": "淋巴细胞%",
    "result": "31.3%",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "26",
    "category": "血常规",
    "itemName": "中性粒细胞%",
    "result": "58.4%",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "27",
    "category": "血常规",
    "itemName": "红细胞",
    "result": "4.22×10^12/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "28",
    "category": "血常规",
    "itemName": "血红蛋白",
    "result": "116 g/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "29",
    "category": "血常规",
    "itemName": "MCHC",
    "result": "307 g/L",
    "conclusion": "偏低",
    "recommendation": "偏低，建议复查血常规。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "30",
    "category": "血常规",
    "itemName": "血小板",
    "result": "248×10^9/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "31",
    "category": "尿常规",
    "itemName": "尿蛋白/尿糖/尿潜血",
    "result": "阴性",
    "conclusion": "正常",
    "recommendation": "均阴性，正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "32",
    "category": "尿常规",
    "itemName": "尿比重",
    "result": "1.025",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "33",
    "category": "尿常规",
    "itemName": "尿酸碱度",
    "result": "6.0",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "34",
    "category": "白带常规",
    "itemName": "清洁度",
    "result": "II 度",
    "conclusion": "正常",
    "recommendation": "II度，正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "35",
    "category": "白带常规",
    "itemName": "白细胞",
    "result": "5-10/HP",
    "conclusion": "正常",
    "recommendation": "正常范围。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "36",
    "category": "白带常规",
    "itemName": "霉菌/滴虫",
    "result": "阴性",
    "conclusion": "正常",
    "recommendation": "阴性，正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "37",
    "category": "血糖",
    "itemName": "空腹血糖",
    "result": "5.62 mmol/L",
    "conclusion": "正常",
    "recommendation": "正常，继续保持健康饮食。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "38",
    "category": "血脂",
    "itemName": "总胆固醇",
    "result": "7.73 mmol/L",
    "conclusion": "升高",
    "recommendation": "升高，建议低脂饮食、锻炼，必要时药物降脂。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "39",
    "category": "血脂",
    "itemName": "甘油三酯",
    "result": "1.75 mmol/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "40",
    "category": "血脂",
    "itemName": "HDL-C",
    "result": "1.77 mmol/L",
    "conclusion": "正常",
    "recommendation": "正常，属保护性因素。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "41",
    "category": "血脂",
    "itemName": "LDL-C",
    "result": "3.60 mmol/L",
    "conclusion": "升高",
    "recommendation": "升高，建议饮食控制、运动，必要时药物治疗。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "42",
    "category": "肝功能",
    "itemName": "ALT",
    "result": "31 U/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "43",
    "category": "肝功能",
    "itemName": "AST",
    "result": "20 U/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "44",
    "category": "肝功能",
    "itemName": "GGT",
    "result": "23 U/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "45",
    "category": "肝功能",
    "itemName": "总蛋白",
    "result": "72 g/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "46",
    "category": "肝功能",
    "itemName": "白蛋白",
    "result": "43.4 g/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "47",
    "category": "肝功能",
    "itemName": "球蛋白",
    "result": "28.6 g/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "48",
    "category": "肝功能",
    "itemName": "总胆红素",
    "result": "18.9 μmol/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "49",
    "category": "肝功能",
    "itemName": "直接胆红素",
    "result": "1.9 μmol/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "50",
    "category": "肝功能",
    "itemName": "间接胆红素",
    "result": "17.0 μmol/L",
    "conclusion": "升高",
    "recommendation": "升高，注意休息，多饮水，避免饮酒，复查或肝病科就诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "51",
    "category": "肾功能",
    "itemName": "尿素",
    "result": "5.37 mmol/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "52",
    "category": "肾功能",
    "itemName": "肌酐",
    "result": "46.1 μmol/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "53",
    "category": "肾功能",
    "itemName": "尿酸",
    "result": "197.4 μmol/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "54",
    "category": "血流变",
    "itemName": "RBC聚集指数",
    "result": "6.14",
    "conclusion": "升高",
    "recommendation": "升高，建议复查血流变，注意心脑血管风险。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "55",
    "category": "血流变",
    "itemName": "全血切变率1",
    "result": "21.62",
    "conclusion": "升高",
    "recommendation": "偏高，建议复查血流变。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "56",
    "category": "心肌酶谱",
    "itemName": "CK",
    "result": "177.73 U/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "57",
    "category": "心肌酶谱",
    "itemName": "CK-MB",
    "result": "19.58 U/L",
    "conclusion": "正常",
    "recommendation": "正常。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "58",
    "category": "心肌酶谱",
    "itemName": "LDH",
    "result": "253.67 U/L",
    "conclusion": "偏高",
    "recommendation": "偏高，建议复查，必要时检查肝脏/心脏。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "59",
    "category": "肿瘤标志物",
    "itemName": "AFP/CEA/CA125等",
    "result": "均正常",
    "conclusion": "正常",
    "recommendation": "均正常，建议定期复查。",
    "riskLevel": "低风险",
    "status": "正常"
},
{
    "id": "60",
    "category": "心电图",
    "itemName": "肢体导联低电压",
    "result": "是",
    "conclusion": "异常",
    "recommendation": "可能与肥胖或心脏疾病相关，建议心内科随诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "61",
    "category": "心电图",
    "itemName": "T波轻度改变",
    "result": "V4-V6",
    "conclusion": "异常",
    "recommendation": "建议复查心电图，如有症状及时就诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "62",
    "category": "影像检查",
    "itemName": "腔隙性脑梗塞",
    "result": "多灶性",
    "conclusion": "异常",
    "recommendation": "建议必要时做MR检查，神经内科随诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "63",
    "category": "影像检查",
    "itemName": "副鼻窦炎",
    "result": "存在",
    "conclusion": "异常",
    "recommendation": "随诊，如有症状可耳鼻喉科就诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "64",
    "category": "影像检查",
    "itemName": "两肺上叶慢性炎性病变",
    "result": "存在",
    "conclusion": "异常",
    "recommendation": "建议与旧片比较，定期复查。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "65",
    "category": "影像检查",
    "itemName": "腰椎骨质增生",
    "result": "L2-3",
    "conclusion": "异常",
    "recommendation": "加强腰背肌锻炼，适当理疗，必要时骨科随诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "66",
    "category": "超声检查",
    "itemName": "乳腺增生",
    "result": "双侧",
    "conclusion": "异常",
    "recommendation": "定期自检、乳腺彩超复查，必要时乳腺外科随诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "67",
    "category": "超声检查",
    "itemName": "甲状腺囊性结节",
    "result": "TI-RADS 2",
    "conclusion": "异常",
    "recommendation": "TI-RADS 2级，良性可能大，建议定期超声复查。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "68",
    "category": "超声检查",
    "itemName": "胆囊息肉",
    "result": "存在",
    "conclusion": "异常",
    "recommendation": "定期复查肝胆超声，必要时外科就诊。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "69",
    "category": "超声检查",
    "itemName": "胆囊壁毛糙",
    "result": "可疑胆囊炎",
    "conclusion": "异常",
    "recommendation": "提示胆囊炎可能，建议饮食清淡，复查。",
    "riskLevel": "中风险",
    "status": "异常"
},
{
    "id": "70",
    "category": "超声检查",
    "itemName": "双肾尿盐结晶",
    "result": "多发",
    "conclusion": "异常",
    "recommendation": "多饮水、运动，避免浓茶和碳酸饮料，定期复查。",
    "riskLevel": "中风险",
    "status": "异常"
}
]
"""

enum ExamDataLoader {
    
    static let demoJSON: String = apiadsss
    static var demoa: [ExamItemaaa] {
        
        guard let data = demoJSON.data(using: .utf8),
              let items = try? JSONDecoder().decode([ExamItemaaa].self, from: data) else {
//            assertionFailure("❌ 未找到 allExamItems.json 或解析失败")
            return []
        }
        return items
    }
}
//// MARK: - 示例数据 & 预览
//// MARK: - 用 JSON 驱动 demo
//extension ExamReportResult {
//    static let demoJSON: String = json
//
//    static var demoa: ExamReportResult {
//        if let data = demoJSON.data(using: .utf8),
//           let api = try? JSONDecoder().decode(ApiExamReport.self, from: data) {
//            return ExamReportResult.fromApi(api)
//        }
//
//        // 兜底：万一解析失败，给一个最小可用的演示
//        return .init(
//            meta: .init(patientName: "演示", relation: "本人", age: 30, gender: "男",
//                        scene: "年度体检", examDate: Date(), hospital: "示例医院", confidence: 90),
//            highRisk: [], midRisk: [], lowRisk: [],
//            normalCount: 0, abnormalCount: 0,
//            sections: [], suggestions: []
//        )
//    }
//}
