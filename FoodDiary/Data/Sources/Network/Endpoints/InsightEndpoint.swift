//
//  InsightEndpoint.swift
//  Data
//

import Foundation

public enum InsightEndpoint {
    case fetch
}

extension InsightEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }

        return url
    }

    public var path: String {
        switch self {
        case .fetch:
            "/me/insights"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .fetch:
            .get
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case .fetch:
            nil
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case .fetch:
            .none
        }
    }

    public var headers: [String: String] {
        switch self {
        case .fetch:
            [:]
        }
    }
}
