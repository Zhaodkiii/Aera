//
//  Keychain.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//


import Security
import Foundation

import Security

enum Keychain {
    // 固定一个 service，保证增删匹配稳定
    private static let service = "com.medapi.auth"   // 自定义即可
    // 如需共享，可加 accessGroup（同 TeamID 的 Keychain Sharing）
    private static let accessGroup: String? = nil    // 例如 "ABCDE12345.com.your.group"

    static func saveToken(_ token: String, account: String = "medapi_token") throws {
        let data = Data(token.utf8)
        // 先删再加，避免重复
        deleteToken(account: account)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, // 避免 iCloud 同步
            kSecValueData as String: data
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup as String] = group }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
    }

    static func loadToken(account: String = "medapi_token") -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup as String] = group }

        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess,
              let data = out as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    static func deleteToken(account: String = "medapi_token") {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup as String] = group }
        SecItemDelete(query as CFDictionary)
    }

    /// 删除本 service 下所有条目（确保“重装首启”彻底清干净）
    static func deleteAllForService() {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup as String] = group }
        SecItemDelete(query as CFDictionary)
    }
}

struct PageResponse<T: Codable>: Codable {
    let count: Int
    let next: URL?
    let previous: URL?
    let results: [T]
}


struct CaseDTO: Codable, Identifiable {
    let id: Int?
    var patient_name: String
    var age: Int
    var gender: String
    var relationship: String
    var chief_complaint: String
    var diagnosis: String
    var symptoms: [String]
    var severity: String           // "low" | "medium" | "high"
    var visit_date: String         // "YYYY-MM-DD"（简单用字符串，不折腾时区）
    var status: String             // "治疗中" 等
    var medications: [String]
    var notes: String?
    var is_favorite: Bool
    var created_at: String?
    var updated_at: String?
}
enum FirstRunGuard {
    private static let firstRunKey = "medapi_has_run_before"

    static func cleanKeychainIfFreshInstall() {
        let hasRun = UserDefaults.standard.bool(forKey: firstRunKey)
        if !hasRun {
            // 重装后的第一次启动：清掉本 app 用到的 Keychain 项
            Keychain.deleteAllForService()
            UserDefaults.standard.set(true, forKey: firstRunKey)
            UserDefaults.standard.synchronize()
        }
    }
}
