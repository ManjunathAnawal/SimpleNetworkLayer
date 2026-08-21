# SimpleNetworkLayer

[![CI](https://github.com/ManjunathAnawal/SimpleNetworkLayer/actions/workflows/ci.yml/badge.svg)](https://github.com/ManjunathAnawal/SimpleNetworkLayer/actions/workflows/ci.yml)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![Platforms](https://img.shields.io/badge/platforms-iOS%2015%2B%20%7C%20macOS%2012%2B-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

A small, dependency-free **async/await networking layer** for Swift. Type-safe endpoints, typed errors, DEBUG-only logging, and full unit-test coverage via `URLProtocol` mocking — no third-party libraries.

## Why

Most apps need ~100 lines of networking, not a framework. This package shows the pattern I use in production:

- **`Endpoint` protocol** — model an API as an enum; paths, methods, query items, and bodies are declared, not string-concatenated.
- **`APIClient`** — one generic `request` method built on `URLSession` + `async/await`.
- **`NetworkError`** — typed failures (`unacceptableStatusCode` carries the response body for server error payloads).
- **Testable by design** — inject a `URLSessionConfiguration` with a mock `URLProtocol`; the test suite never touches the network.

## Installation

Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ManjunathAnawal/SimpleNetworkLayer.git", from: "1.0.0")
]
```

## Usage

### 1. Declare your API as an `Endpoint`

```swift
import SimpleNetworkLayer

enum DogAPI: Endpoint {
    case randomImage
    case imagesByBreed(String, count: Int)

    var baseURL: URL { URL(string: "https://dog.ceo/api")! }

    var path: String {
        switch self {
        case .randomImage:
            return "/breeds/image/random"
        case let .imagesByBreed(breed, count):
            return "/breed/\(breed)/images/random/\(count)"
        }
    }
}
```

### 2. Make requests

```swift
struct DogImage: Decodable {
    let message: String
    let status: String
}

let client = APIClient()
let dog: DogImage = try await client.request(DogAPI.randomImage)
```

### 3. POST with a JSON body

```swift
enum UserAPI: Endpoint {
    case create(name: String)

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var method: HTTPMethod { .post }
    var body: Data? {
        guard case let .create(name) = self else { return nil }
        return try? Self.jsonBody(["name": name])
    }
}
```

`Content-Type: application/json` is set automatically when a body is present.

### 4. Handle errors

```swift
do {
    let user: User = try await client.request(UserAPI.create(name: "Manju"))
} catch let NetworkError.unacceptableStatusCode(code, data) {
    // Server-side failure — `data` holds the error payload for decoding.
} catch let NetworkError.transportError(description) {
    // Offline, timeout, TLS…
} catch let NetworkError.decodingFailed(description) {
    // Contract mismatch.
}
```

## Testing your own code

Inject a mock `URLProtocol` — same technique this package's test suite uses:

```swift
let configuration = URLSessionConfiguration.ephemeral
configuration.protocolClasses = [MockURLProtocol.self]
let client = APIClient(configuration: configuration)
```

Run the suite:

```bash
swift test
```

## License

MIT — see [LICENSE](LICENSE).
