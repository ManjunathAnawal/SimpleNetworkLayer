//
//  HTTPMethod.swift
//  SimpleNetworkLayer
//
//  Created by Manjunath Anawal.
//

import Foundation

/// HTTP request methods supported by the network layer.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
