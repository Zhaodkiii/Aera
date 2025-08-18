//
//  CacheFetchPolicy.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/18.
//

import Foundation

// MARK: - CacheFetchPolicy（可用于上层控制拿缓存还是强制网络）
enum CacheFetchPolicy {
    case fromCacheOnly
    case fetchCurrent
    case cachedOrFetched
    case notStaleCachedOrFetched

    static let `default`: CacheFetchPolicy = .cachedOrFetched
}

// MARK: - ETag 缓存
final class ETagManager {
    // 约定的头字段（与服务端协定）
    enum RequestHeader: String {
        case eTag = "If-None-Match"
        case eTagValidationTime = "X-Last-Refresh-Time"
    }
    enum ResponseHeader: String {
        case eTag = "ETag"
        case requestTime = "X-Request-Time"
        case retryAfter = "Retry-After"
    }

    private let store = UserDefaults(suiteName: "com.example.etag") ?? .standard
    private func key(for url: URLRequest) -> String? { url.url?.absoluteString }

    func eTagHeaders(for request: URLRequest, refreshIfRetried: Bool) -> HTTPHeaders {
        guard let k = key(for: request),
              let cached = store.data(forKey: k),
              let item = try? JSONDecoder().decode(CacheItem.self, from: cached),
              !refreshIfRetried
        else {
            return [:]
        }
        var h: HTTPHeaders = [RequestHeader.eTag.rawValue: item.tag]
        if let t = item.validationTime {
            h[RequestHeader.eTagValidationTime.rawValue] = String(Int(t.timeIntervalSince1970 * 1000))
        }
        return h
    }

    func cachedBody(for request: URLRequest) -> Data? {
        guard let k = key(for: request),
              let cached = store.data(forKey: k),
              let item = try? JSONDecoder().decode(CacheItem.self, from: cached)
        else { return nil }
        return item.data
    }

    func storeIfPossible(response: Data, headers: [AnyHashable: Any], for request: URLRequest, status: Int) {
        guard let k = key(for: request),
              let etag = headers[ResponseHeader.eTag.rawValue] as? String
        else { return }
        let now = Date()
        let item = CacheItem(tag: etag, status: status, data: response, validationTime: now)
        if let data = try? JSONEncoder().encode(item) {
            store.set(data, forKey: k)
        }
    }

    func clear() {
        store.dictionaryRepresentation().keys.forEach { store.removeObject(forKey: $0) }
    }

    // 存储模型
    struct CacheItem: Codable {
        let tag: String
        let status: Int
        let data: Data
        var validationTime: Date?
    }
}

// MARK: - （可选）回调合并，防止同请求并发打爆
protocol CacheKeyProviding { var cacheKey: String { get } }

final class CallbackCache<T: CacheKeyProviding> {
    private var dict: [String: [T]] = [:]
    private let lock = NSLock()

    enum Status { case appended, first }
    func add(_ cb: T) -> Status {
        lock.lock(); defer { lock.unlock() }
        var list = dict[cb.cacheKey] ?? []
        let status: Status = list.isEmpty ? .first : .appended
        list.append(cb)
        dict[cb.cacheKey] = list
        return status
    }

    func drain(_ key: String, perform: (T) -> Void) {
        lock.lock()
        let items = dict.removeValue(forKey: key) ?? []
        lock.unlock()
        items.forEach(perform)
    }
}
