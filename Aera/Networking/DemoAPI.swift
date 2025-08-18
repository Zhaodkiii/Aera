//
//  DemoAPI.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/18.
//


import Foundation

struct DemoAPI: Endpoint {
    static let serverURL = URL(string: "http://127.0.0.1:8000")!
    var path: String
    var name: String
    var requiresAuth: Bool { false }
    var usesETag: Bool { false }      // individual override below
    var fallbackHosts: [URL] {
        [URL(string: "http://127.0.0.1:8001")!]
    }

    static func ping() -> DemoAPI { .init(path: "/ping", name: "ping") }
    static func createNote() -> DemoAPI { .init(path: "/notes", name: "create_note") }
    static func bad() -> DemoAPI { .init(path: "/bad", name: "bad_request") }
    static func unauth() -> DemoAPI { .init(path: "/unauth", name: "unauthorized") }
    static func tooMany() -> DemoAPI { .init(path: "/too_many", name: "too_many") }
    static func serverError() -> DemoAPI { .init(path: "/boom", name: "server_error") }
    static func redirect() -> DemoAPI { .init(path: "/redirect", name: "redirect307") }
    static func etag() -> DemoAPI {
        var a = DemoAPI(path: "/etag", name: "etag")
        // 对这个接口启用 ETag
        withUnsafeMutablePointer(to: &a) { p in
            // 通过扩展：我们在请求时把 usesETag 决定下来（见下面请求处）
        }
        return a
    }
    static func maybe500() -> DemoAPI { .init(path: "/maybe500", name: "maybe500") }
}
struct NoteBody: HTTPRequestBody { let title: String; let content: String }
struct PingDTO: Decodable { let ok: Bool; let hello: String? }
struct NoteDTO: Decodable { let id: Int; let title: String?; let content: String? }
struct ETagDTO: Decodable { let version: Int; let data: [Int] }
