//
//  DiaryEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/18/26.
//

import Foundation

public enum DiaryEndpoint {
    case fetchMonthly(startDate: String, endDate: String, testMode: Bool)
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
        case .fetchMonthly:
            "/diaries"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .fetchMonthly:
            .get
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case let .fetchMonthly(startDate, endDate, testMode):
            [
                "start_date": startDate,
                "end_date": endDate,
                "test_mode": "\(testMode)",
            ]
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case .fetchMonthly:
            .none
        }
    }

    public var headers: [String: String] {
        switch self {
        case .fetchMonthly:
            [:]
        }
    }
}
