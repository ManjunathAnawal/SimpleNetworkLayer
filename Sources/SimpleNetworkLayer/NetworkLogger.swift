//
//  NetworkLogger.swift
//  SimpleNetworkLayer
//
//  Created by Manjunath Anawal.
//

import Foundation
import os

/// Lightweight request/response logger. Logs only in DEBUG builds.
struct NetworkLogger: Sendable {
    private static let logger = Logger(subsystem: "SimpleNetworkLayer", category: "network")

    let isEnabled: Bool

    func logRequest(_ request: URLRequest) {
        #if DEBUG
        guard isEnabled else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        Self.logger.debug("➡️ \(method, privacy: .public) \(url, privacy: .public)")
        #endif
    }

    func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval) {
        #if DEBUG
        guard isEnabled else { return }
        let url = response.url?.absoluteString ?? "?"
        let ms = Int(duration * 1000)
        Self.logger.debug(
            "⬅️ \(response.statusCode) \(url, privacy: .public) (\(data.count) bytes, \(ms) ms)"
        )
        #endif
    }

    func logError(_ error: Error, request: URLRequest) {
        #if DEBUG
        guard isEnabled else { return }
        let url = request.url?.absoluteString ?? "?"
        Self.logger.error("❌ \(url, privacy: .public) — \(String(describing: error), privacy: .public)")
        #endif
    }
}
