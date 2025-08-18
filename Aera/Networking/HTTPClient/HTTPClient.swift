////
////  HTTPClient.swift
////  Aera
////
////  Created by Dream 話 on 2025/8/18.
////
//// Network Module Demo – similar architecture to RevenueCat (HTTPClient, ETagManager, etc).
//// Modules covered:
//// 1) Network request (HTTPClient: building requests, default headers, URLSession).
//// 2) Error handling (NetworkError: mapping HTTP status codes and JSON errors).
//// 3) Caching (ETagManager: using ETag for response caching, handling 304 Not Modified).
//// 4) Response models (HTTPResponseBody protocol, HTTPResponse struct, JSON parsing).
//// 5) Signing & verification (SignatureUtil: signing requests and verifying responses).
//// 6) Callback deduplication (HTTPClient.pendingRequests to avoid duplicate requests).
//
//import Foundation
//import CryptoKit
//
//// 1. Network Request Module: HTTPClient encapsulates GET request logic.
//class HTTPClient {
//    private let baseURL: URL
//    private let session: URLSession
//    private let etagManager: ETagManager
//    
//    // Use a dictionary to cache callbacks for identical requests to prevent duplicate network calls.
//    private var pendingRequests: [String: [(Result<ResponseTuple, NetworkError>) -> Void]] = [:]
//    private let pendingRequestsLock = NSLock()
//    
//    // Define a tuple type for raw response data and status.
//    private typealias ResponseTuple = (statusCode: Int, data: Data)
//    
//    // Default HTTP headers for all requests (static headers).
//    private let defaultHeaders: [String: String] = [
//        "Accept": "application/json",
//        "Content-Type": "application/json"
//    ]
//    
//    init(baseURL: URL) {
//        self.baseURL = baseURL
//        self.etagManager = ETagManager()
//        // Configure URLSession with no built-in caching (we'll use ETagManager for caching).
//        let config = URLSessionConfiguration.default
//        config.requestCachePolicy = .reloadIgnoringLocalCacheData
//        config.urlCache = nil
//        self.session = URLSession(configuration: config)
//    }
//    
//    // Perform a GET request to the given path, expecting a response body of type T.
//    func get<T: HTTPResponseBody>(_ path: String, completion: @escaping (Result<HTTPResponse<T>, NetworkError>) -> Void) {
//        // Build the full URL from base URL and the provided path.
//        guard let url = URL(string: path, relativeTo: baseURL) else {
//            completion(.failure(.invalidURL))
//            return
//        }
//        // Unique key for this request (method + URL) for deduplication.
//        let requestKey = "GET:\(url.absoluteString)"
//        
//        // Check if a request for this key is already in progress.
//        pendingRequestsLock.lock()
//        if var callbacks = pendingRequests[requestKey] {
//            // A request is in-flight; append the new completion to the list and return (no new network call).
//            callbacks.append({ result in
//                // Transform the raw result (ResponseTuple) into the typed Result<HTTPResponse<T>, NetworkError>.
//                let transformed = result.flatMap { tuple -> Result<HTTPResponse<T>, NetworkError> in
//                    do {
//                        let decoder = JSONDecoder()
//                        let decodedObject = try decoder.decode(T.self, from: tuple.data)
//                        let httpResponse = HTTPResponse(statusCode: tuple.statusCode, body: decodedObject)
//                        return .success(httpResponse)
//                    } catch {
//                        return .failure(.decodeError(error))
//                    }
//                }
//                // Call the original completion on the main thread.
//                DispatchQueue.main.async {
//                    completion(transformed)
//                }
//            })
//            pendingRequests[requestKey] = callbacks
//            pendingRequestsLock.unlock()
//            return  // Another request is already handling this URL, so just wait for its result.
//        } else {
//            // No existing request for this key, start a new one.
//            pendingRequests[requestKey] = [
//                { result in
//                    let transformed = result.flatMap { tuple -> Result<HTTPResponse<T>, NetworkError> in
//                        do {
//                            let decoder = JSONDecoder()
//                            let decodedObject = try decoder.decode(T.self, from: tuple.data)
//                            let httpResponse = HTTPResponse(statusCode: tuple.statusCode, body: decodedObject)
//                            return .success(httpResponse)
//                        } catch {
//                            return .failure(.decodeError(error))
//                        }
//                    }
//                    DispatchQueue.main.async {
//                        completion(transformed)
//                    }
//                }
//            ]
//            pendingRequestsLock.unlock()
//        }
//        
//        // Build URLRequest for the GET request.
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        // Set default headers.
//        for (header, value) in defaultHeaders {
//            request.setValue(value, forHTTPHeaderField: header)
//        }
//        // If we have a cached ETag for this URL, include it in the request headers to enable 304 responses.
//        if let etag = etagManager.getETag(for: url) {
//            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
//        }
//        // Sign the request (adds an X-Signature header).
//        SignatureUtil.sign(request: &request)
//        
//        // Execute the network request.
//        let task = session.dataTask(with: request) { [weak self] data, response, error in
//            guard let self = self else { return }
//            // Prepare a result to broadcast to all callbacks waiting on this request.
//            var result: Result<ResponseTuple, NetworkError>
//            
//            defer {
//                // Deliver the result to all pending callbacks for this request, then clear them.
//                self.pendingRequestsLock.lock()
//                let callbacks = self.pendingRequests.removeValue(forKey: requestKey)
//                self.pendingRequestsLock.unlock()
//                callbacks?.forEach { $0(result) }
//            }
//            
//            // Handle low-level request errors (e.g., no internet connection, timeout).
//            if let err = error {
//                result = .failure(.requestFailed(err))
//                return
//            }
//            // Ensure we have an HTTPURLResponse with status code.
//            guard let httpResponse = response as? HTTPURLResponse else {
//                result = .failure(.invalidResponse)
//                return
//            }
//            let status = httpResponse.statusCode
//            // If server indicates content not modified (304), use cached data.
//            if status == 304 {
//                if let cachedData = self.etagManager.getCachedData(for: url) {
//                    // Use cached response data since content is unchanged.
//                    result = .success((statusCode: 304, data: cachedData))
//                } else {
//                    // 304 received but no cached data available – return an error.
//                    result = .failure(.noCachedData)
//                }
//                return
//            }
//            // For HTTP error status codes (>= 400), try to parse error message and return a NetworkError.
//            if status >= 400 {
//                if let data = data {
//                    // Attempt to decode a structured error from the response JSON.
//                    if let apiError = try? JSONDecoder().decode(APIError.self, from: data),
//                       let message = apiError.message {
//                        result = .failure(.httpError(statusCode: status, message: message))
//                    } else {
//                        result = .failure(.httpError(statusCode: status, message: "HTTP \(status) error"))
//                    }
//                } else {
//                    result = .failure(.httpError(statusCode: status, message: "HTTP \(status) error"))
//                }
//                return
//            }
//            // At this point, status is 200–299 (successful response with content).
//            guard let data = data else {
//                // No data in a success response is unexpected.
//                result = .failure(.invalidResponse)
//                return
//            }
//            // Verify the response's signature (if a signature header is present).
//            if !SignatureUtil.verify(response: httpResponse, data: data) {
//                result = .failure(.invalidSignature)
//                return
//            }
//            // Store the data in cache if an ETag is provided in the response headers.
//            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
//                self.etagManager.storeResponse(url: url, data: data, eTag: etag)
//            }
//            // Package the raw response data and status code as a successful result.
//            result = .success((statusCode: status, data: data))
//        }
//        task.resume()
//    }
//}
//
//// 2. Error Handling Module: Define a custom Error type for network errors.
//enum NetworkError: Error {
//    case invalidURL                    // Malformed URL
//    case requestFailed(Error)          // Underlying URLSession error (no network, etc.)
//    case invalidResponse               // Missing or invalid HTTPURLResponse/data
//    case httpError(statusCode: Int, message: String)  // HTTP status code indicates error, with message
//    case decodeError(Error)            // JSON decoding of response failed
//    case invalidSignature              // Response signature validation failed
//    case noCachedData                  // 304 received but no cached data available
//}
//
//// 3. Cache Management Module: ETagManager for caching responses using ETag.
//class ETagManager {
//    private var cache: [URL: (etag: String, data: Data)] = [:]
//    private let lock = NSLock()
//    
//    // Get stored ETag for a URL (to send in If-None-Match).
//    func getETag(for url: URL) -> String? {
//        lock.lock()
//        defer { lock.unlock() }
//        return cache[url]?.etag
//    }
//    
//    // Get cached response data for a URL.
//    func getCachedData(for url: URL) -> Data? {
//        lock.lock()
//        defer { lock.unlock() }
//        return cache[url]?.data
//    }
//    
//    // Store or update the cached data and ETag for a URL.
//    func storeResponse(url: URL, data: Data, eTag: String) {
//        lock.lock()
//        cache[url] = (eTag, data)
//        lock.unlock()
//    }
//}
//
//// 4. Response Handling & Data Structures:
//protocol HTTPResponseBody: Decodable { }  // Marker protocol for models that can be decoded from JSON.
//
//// Generic HTTPResponse container to hold status code and decoded body.
//struct HTTPResponse<Body: HTTPResponseBody> {
//    let statusCode: Int
//    let body: Body
//}
//
//// Example response model conforming to HTTPResponseBody.
//struct UserInfo: HTTPResponseBody {
//    let id: String
//    let name: String
//}
//
//// If the API returns an error payload in JSON, define a structure to parse it.
//struct APIError: Decodable {
//    let code: Int?
//    let message: String?
//}
//
//// 5. Signature & Verification Module: sign outgoing requests and verify incoming responses.
//struct SignatureUtil {
//    // Secret key shared with server (for demo purposes, a constant string).
//    private static let secretKey = "my_shared_secret"
//    
//    // Sign the request by adding an "X-Signature" header (HMAC-SHA256 of method + path).
//    static func sign(request: inout URLRequest) {
//        guard let url = request.url else { return }
//        let path = url.path    // using path as the data to sign (could include query or body if needed)
//        let method = request.httpMethod ?? "GET"
//        // Compute HMAC-SHA256 signature.
//        let dataToSign = Data((method + path).utf8)
//        let key = SymmetricKey(data: Data(secretKey.utf8))
//        let signature = HMAC<SHA256>.authenticationCode(for: dataToSign, using: key)
//        // Convert signature to hex string.
//        let signatureHex = signature.map { String(format: "%02x", $0) }.joined()
//        // Set the signature header.
//        request.setValue(signatureHex, forHTTPHeaderField: "X-Signature")
//        // (In a real implementation, you might also include a timestamp or nonce to prevent replay attacks.)
//    }
//    
//    // Verify the response by checking the "X-Signature" header against our own HMAC of the response data.
//    static func verify(response: HTTPURLResponse, data: Data) -> Bool {
//        // If there's no signature header in the response, skip verification.
//        guard let serverSignature = response.value(forHTTPHeaderField: "X-Signature") else {
//            return true
//        }
//        let key = SymmetricKey(data: Data(secretKey.utf8))
//        // Compute expected HMAC of the response data.
//        let expectedSignature = HMAC<SHA256>.authenticationCode(for: data, using: key)
//        let expectedSignatureHex = expectedSignature.map { String(format: "%02x", $0) }.joined()
//        // Compare the server's signature with our expected signature.
//        return serverSignature == expectedSignatureHex
//    }
//}
