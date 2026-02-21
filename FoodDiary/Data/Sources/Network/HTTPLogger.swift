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
            var message = "[Request] [\(method)] \(url)"
            if let body = request.httpBody {
                message += "\nBody:\n\(prettyJSON(body))"
            }
            logger.info("\(message)")
        #endif
    }

    func logResponse(_ response: URLResponse, statusCode: Int, data: Data) {
        #if DEBUG
            let url = response.url?.absoluteString ?? "nil"
            var message = "[Response] [\(statusCode)] \(url)"
            message += "\nBody:\n\(prettyJSON(data))"
            if (200..<300).contains(statusCode) {
                logger.info("\(message)")
            } else {
                logger.error("\(message)")
            }
        #endif
    }

    func logRequestBody(_ body: Data?) {
        #if DEBUG
            guard let body else {
                logger.info("[Request Body] (empty)")
                return
            }
            let bodyString = String(data: body, encoding: .utf8) ?? "(binary \(body.count) bytes)"
            logger.info("[Request Body] \(bodyString)")
        #endif
    }

    func logResponseBody(_ data: Data) {
        #if DEBUG
            let bodyString = String(data: data, encoding: .utf8) ?? "(binary \(data.count) bytes)"
            logger.info("[Response Body] \(bodyString)")
        #endif
    }

    func logError(_ error: Error, context: String) {
        #if DEBUG
            logger.error("[Error] \(context): \(error.localizedDescription)")
        #endif
    }
}

private extension HTTPLogger {
    func prettyJSON(_ data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: pretty, encoding: .utf8) else {
            return String(data: data, encoding: .utf8) ?? "(binary \(data.count) bytes)"
        }
        return string
    }
}
