//
//  RestaurantEndpoint.swift
//  Data
//

import Foundation

public enum RestaurantEndpoint {
    case search(diaryId: Int?, keyword: String?, page: Int, size: Int)
}

extension RestaurantEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }
        return url
    }

    public var path: String {
        switch self {
        case .search:
            "/restaurant/search"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .search:
            .get
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case let .search(diaryId, keyword, page, size):
            var params: [String: String] = [
                "page": String(page),
                "size": String(size)
            ]
            if let diaryId {
                params["diary_id"] = String(diaryId)
            }
            if let keyword, !keyword.isEmpty {
                params["keyword"] = keyword
            }
            return params
        }
    }

    public var bodyParameters: HTTPBody {
        .none
    }

    public var headers: [String: String] {
        [:]
    }
}
