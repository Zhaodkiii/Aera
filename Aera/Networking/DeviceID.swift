//
//  DeviceID.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/23.
//


import Foundation
import Security

enum DeviceID {
    private static let account = "permanent_device_id"
    private static let service = "com.Zhaodk.device"

    static func get() -> String {
        if let existing = loadFromKeychain() {
            return existing
        }
        let newID = UUID().uuidString
        saveToKeychain(newID)
        return newID
    }

    private static func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveToKeychain(_ id: String) {
        let data = Data(id.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary) // 避免重复
        SecItemAdd(query as CFDictionary, nil)
    }
}
