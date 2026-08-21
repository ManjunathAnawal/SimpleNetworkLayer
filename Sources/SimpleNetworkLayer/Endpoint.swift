//
//  Endpoint.swift
//  SimpleNetworkLayer
//
//  Created by Manjunath Anawal.
//

import Foundation

/// Describes a single API endpoint.
///
/// Conform an enum to `Endpoint` to model an API surface:
///
/// ```swift
/// enum DogAPI: Endpoint {
///     case randomImage
///     case breeds
///
///     var baseURL: URL { URL(string: "https://dog.ceo/api")! }
///
///     var path: String {
///         switch self {
///         case .randomImage: return "/breeds/image/random"
///         case .breeds: return "/breeds/list/all"
///         }
///     }
///
///     var method: HTTPMethod { .get }
/// }
/// ```
public protocol Endpoint: Sendable {
    /// Base URL of the API, e.g. `https://api.example.com`.
    var baseURL: URL { get }
    /// Path appended to ``baseURL``, e.g. `/users/42`.
    var path: String { get }
    /// HTTP method. Defaults to `.get`.
    var method: HTTPMethod { get }
    /// Additional HTTP headers. Defaults to empty.
    var headers: [String: String] { get }
    /// URL query items. Defaults to empty.
    var queryItems: [URLQueryItem] { get }
    /// Raw HTTP body. Defaults to `nil`. Use ``body(encoding:)`` helpers for JSON.
    var body: Data? { get }
    /// Per-request timeout in seconds. Defaults to 30.
    var timeout: TimeInterval { get }
}

// MARK: - Defaults

public extension Endpoint {
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem] { [] }
    var body: Data? { nil }
    var timeout: TimeInterval { 30 }
}

// MARK: - URLRequest construction

extension Endpoint {
    func makeURLRequest() throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.httpBody = body
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if body != nil, request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}

// MARK: - JSON body helper

public extension Endpoint {
    /// Encodes an `Encodable` value as a JSON body.
    static func jsonBody<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        try encoder.encode(value)
    }
}
