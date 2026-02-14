//
//  HTTPLogger.swift
//  Data
//

import Foundation
import Logging

public struct HTTPLogger {
    private let logger: Logger

    public init(logger: Logger = Logger(label: "com.fooddiary.network")) {
        self.logger = logger
    }

    func logRequest(_ request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "nil"
        logger.info("[Request] [\(method)] \(url)")
        #endif
    }

    func logResponse(_ response: URLResponse, statusCode: Int) {
        #if DEBUG
        let url = response.url?.absoluteString ?? "nil"
        if (200..<300).contains(statusCode) {
            logger.info("[Response] [\(statusCode)] \(url)")
        } else {
            logger.error("[Response] [\(statusCode)] \(url)")
        }
        #endif
    }

    func logDecodedModel<T>(_ model: T) {
        #if DEBUG
        logger.info("[Decoded] \(String(describing: type(of: model))): \(model)")
        #endif
    }

    func logErrorResponse(_ data: Data, statusCode: Int) {
        #if DEBUG
        let body = String(data: data, encoding: .utf8) ?? "Unable to decode response body"
        logger.error("[Error Response] [\(statusCode)] \(body)")
        #endif
    }

    func logError(_ error: Error, context: String) {
        #if DEBUG
        logger.error("[Error] \(context): \(error.localizedDescription)")
        #endif
    }
}
