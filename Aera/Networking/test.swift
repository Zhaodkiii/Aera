//
//  test.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/18.
//

import Foundation

// 1) 定义你的 Endpoint
struct MyAPI: Endpoint {
    static let serverURL = URL(string: "https://api.yourdomain.com")!
    var requiresAuth: Bool { true }
    var usesETag: Bool { true }
    var path: String
    var name: String
    var fallbackHosts: [URL] {
        [URL(string: "https://api-backup.yourdomain.com")!]
    }

    static func getUser(id: String) -> MyAPI {
        .init(path: "/v1/users/\(id)", name: "get_user")
    }
    static func postNote() -> MyAPI {
        .init(path: "/v1/notes", name: "post_note")
    }
}

// 2) 定义请求体/响应体
struct CreateNoteBody: HTTPRequestBody {
    let title: String
    let content: String
}
struct UserDTO: Decodable {}       // 作为 HTTPResponseBody 已支持 Decodable
