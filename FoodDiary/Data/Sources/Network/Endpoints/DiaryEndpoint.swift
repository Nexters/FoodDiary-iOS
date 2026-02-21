//
//  DiaryEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/18/26.
//

import Foundation

public enum DiaryEndpoint {
    case byDateRange(startDate: String, endDate: String, testMode: Bool)
    case byDateRangeSummary(startDate: String, endDate: String, testMode: Bool)
}

extension DiaryEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }

        return url
    }

    public var path: String {
        switch self {
        case .byDateRange:
            "/diaries"
        case .byDateRangeSummary:
            "/diaries/summary"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .byDateRange, .byDateRangeSummary:
            .get
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case .byDateRange(let startDate, let endDate, let testMode):
            var params: [String: String] = [
                "start_date": startDate,
                "end_date": endDate,
            ]
            if testMode {
                params["test_mode"] = String(testMode)
            }
            return params
        case .byDateRangeSummary(let startDate, let endDate, let testMode):
            var params: [String: String] = [
                "start_date": startDate,
                "end_date": endDate,
            ]
            if testMode {
                params["test_mode"] = String(testMode)
            }
            return params
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case .byDateRange, .byDateRangeSummary:
            .none
        }
    }

    public var headers: [String: String] {
        switch self {
        case .byDateRange, .byDateRangeSummary:
            [:]
        }
    }
}
