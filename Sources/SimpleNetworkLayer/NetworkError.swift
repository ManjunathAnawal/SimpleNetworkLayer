//
//  NetworkError.swift
//  SimpleNetworkLayer
//
//  Created by Manjunath Anawal.
//

import Foundation

/// Errors thrown by ``APIClient``.
public enum NetworkError: Error, Equatable {
    /// The endpoint produced an invalid URL.
    case invalidURL
    /// The response was not an `HTTPURLResponse`.
    case invalidResponse
    /// The server returned a non-2xx status code. Carries the code and raw body for diagnostics.
    case unacceptableStatusCode(Int, data: Data)
    /// Decoding the response body failed.
    case decodingFailed(description: String)
    /// The underlying transport failed (no connection, timeout, TLS, …).
    case transportError(description: String)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL could not be constructed."
        case .invalidResponse:
            return "The server response was not a valid HTTP response."
        case let .unacceptableStatusCode(code, _):
            return "The server responded with status code \(code)."
        case let .decodingFailed(description):
            return "Failed to decode the response: \(description)"
        case let .transportError(description):
            return "Network transport failed: \(description)"
        }
    }
}
