//
//  DiariesEndpoint.swift
//  Data
//

import Foundation

public enum DiariesEndpoint {
    case fetchByDateRange(startDate: String, endDate: String, testMode: Bool)
}

extension DiariesEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }
        return url
    }

    public var path: String {
        switch self {
        case .fetchByDateRange:
            "/diaries"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .fetchByDateRange:
            .get
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case let .fetchByDateRange(startDate, endDate, testMode):
            var params: [String: String] = [
                "start_date": startDate,
                "end_date": endDate
            ]
            if testMode {
                params["test_mode"] = "true"
            }
            return params
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case .fetchByDateRange:
            .none
        }
    }

    public var headers: [String: String] {
        switch self {
        case .fetchByDateRange:
            [:]
        }
    }
}
