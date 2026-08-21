//
//  SimpleNetworkLayerTests.swift
//  SimpleNetworkLayerTests
//
//  Created by Manjunath Anawal.
//

import XCTest
@testable import SimpleNetworkLayer

// MARK: - Fixtures

private struct User: Codable, Equatable {
    let id: Int
    let name: String
}

private enum TestAPI: Endpoint {
    case user(id: Int)
    case createUser(name: String)
    case search(term: String)

    var baseURL: URL { URL(string: "https://api.example.com")! }

    var path: String {
        switch self {
        case let .user(id): return "/users/\(id)"
        case .createUser: return "/users"
        case .search: return "/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .createUser: return .post
        default: return .get
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .search(term): return [URLQueryItem(name: "q", value: term)]
        default: return []
        }
    }

    var body: Data? {
        switch self {
        case let .createUser(name):
            return try? Self.jsonBody(["name": name])
        default:
            return nil
        }
    }
}

// MARK: - Tests

final class SimpleNetworkLayerTests: XCTestCase {

    private var client: APIClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        client = APIClient(configuration: configuration, loggingEnabled: false)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        client = nil
        super.tearDown()
    }

    private func stub(status: Int, json: String) {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(json.utf8))
        }
    }

    // MARK: Decoding

    func test_request_decodesSuccessResponse() async throws {
        stub(status: 200, json: #"{"id": 42, "name": "Manju"}"#)

        let user: User = try await client.request(TestAPI.user(id: 42))

        XCTAssertEqual(user, User(id: 42, name: "Manju"))
    }

    func test_request_throwsDecodingFailed_onMalformedJSON() async {
        stub(status: 200, json: #"{"id": "not-an-int"}"#)

        do {
            let _: User = try await client.request(TestAPI.user(id: 1))
            XCTFail("Expected decodingFailed")
        } catch let error as NetworkError {
            guard case .decodingFailed = error else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }

    // MARK: Status codes

    func test_request_throwsUnacceptableStatusCode_on404_withBody() async {
        stub(status: 404, json: #"{"error": "not found"}"#)

        do {
            let _: User = try await client.request(TestAPI.user(id: 999))
            XCTFail("Expected unacceptableStatusCode")
        } catch let NetworkError.unacceptableStatusCode(code, data) {
            XCTAssertEqual(code, 404)
            XCTAssertEqual(String(decoding: data, as: UTF8.self), #"{"error": "not found"}"#)
        } catch {
            XCTFail("Expected unacceptableStatusCode, got \(error)")
        }
    }

    func test_requestData_returnsRawBody_on2xx() async throws {
        stub(status: 204, json: "")

        let data = try await client.requestData(TestAPI.user(id: 1))

        XCTAssertTrue(data.isEmpty)
    }

    // MARK: Transport

    func test_request_throwsTransportError_whenConnectionFails() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            let _: User = try await client.request(TestAPI.user(id: 1))
            XCTFail("Expected transportError")
        } catch let error as NetworkError {
            guard case .transportError = error else {
                return XCTFail("Expected transportError, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }

    // MARK: URLRequest construction

    func test_endpoint_buildsURLWithQueryItems() throws {
        let request = try TestAPI.search(term: "swift ios").makeURLRequest()

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.example.com/search?q=swift%20ios"
        )
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_endpoint_post_setsBodyAndDefaultContentType() throws {
        let request = try TestAPI.createUser(name: "Manju").makeURLRequest()

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = try XCTUnwrap(request.httpBody)
        let decoded = try JSONDecoder().decode([String: String].self, from: body)
        XCTAssertEqual(decoded, ["name": "Manju"])
    }
}
