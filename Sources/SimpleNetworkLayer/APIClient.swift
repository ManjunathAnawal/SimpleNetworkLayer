//
//  APIClient.swift
//  SimpleNetworkLayer
//
//  Created by Manjunath Anawal.
//

import Foundation

/// A small, testable async/await HTTP client over `URLSession`.
///
/// ```swift
/// let client = APIClient()
/// let dog: DogImage = try await client.request(DogAPI.randomImage)
/// ```
///
/// Inject a custom `URLSessionConfiguration` (e.g. with a mock `URLProtocol`)
/// to unit-test without hitting the network.
public struct APIClient: Sendable {

    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger: NetworkLogger

    /// - Parameters:
    ///   - configuration: Session configuration. Defaults to `.default`.
    ///   - decoder: Decoder for response bodies. Defaults to `JSONDecoder()`.
    ///   - loggingEnabled: Console logging of requests/responses in DEBUG builds. Defaults to `true`.
    public init(
        configuration: URLSessionConfiguration = .default,
        decoder: JSONDecoder = JSONDecoder(),
        loggingEnabled: Bool = true
    ) {
        self.session = URLSession(configuration: configuration)
        self.decoder = decoder
        self.logger = NetworkLogger(isEnabled: loggingEnabled)
    }

    // MARK: - Public API

    /// Performs the request and decodes the response body into `T`.
    public func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let data = try await requestData(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(description: String(describing: error))
        }
    }

    /// Performs the request and returns the raw response body.
    /// Use for endpoints with empty or non-JSON responses.
    @discardableResult
    public func requestData(_ endpoint: Endpoint) async throws -> Data {
        let request = try endpoint.makeURLRequest()
        logger.logRequest(request)

        let start = Date()
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.logError(error, request: request)
            throw NetworkError.transportError(description: String(describing: error))
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        logger.logResponse(http, data: data, duration: Date().timeIntervalSince(start))

        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.unacceptableStatusCode(http.statusCode, data: data)
        }
        return data
    }
}
