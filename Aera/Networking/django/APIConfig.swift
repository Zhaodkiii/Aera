//
//  APIConfig.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/22.
//

import Foundation

enum APIConfig {
    static let baseURL = URL(string: "http://192.168.31.191:8000")! // 改成你的后端地址
    static let tokenEndpoint = URL(string: "/api/auth/token/", relativeTo: baseURL)!
    static let loginWithPassword = URL(string: "/api/auth/login/password", relativeTo: baseURL)!
    static let casesBase = URL(string: "/api/cases/", relativeTo: baseURL)!
}
