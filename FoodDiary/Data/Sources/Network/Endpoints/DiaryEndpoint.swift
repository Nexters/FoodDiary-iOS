//
//  DiaryEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/18/26.
//

import Foundation

public enum DiaryEndpoint {
    case fetchMonthlyTest(startDate: String, endDate: String)
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
        case .fetchMonthlyTest:
            "/diaries"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .fetchMonthlyTest:
            .get
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case let .fetchMonthlyTest(startDate, endDate):
            [
                "start_date": startDate,
                "end_date": endDate,
                "test_mode": "true",
            ]
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case .fetchMonthlyTest:
            .none
        }
    }

    public var headers: [String: String] {
        switch self {
        case .fetchMonthlyTest:
            [:]
        }
    }
}
