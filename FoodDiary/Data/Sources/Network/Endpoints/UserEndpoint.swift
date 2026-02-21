//
//  UserEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation
import Domain

public enum UserEndpoint {
    case withdraw
}

extension UserEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }

        return url
    }

    public var path: String {
        switch self {
        case .withdraw:
            "/users/me"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .withdraw:
            .delete
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case .withdraw:
            nil
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case .withdraw:
            return .none
        }
    }

    public var headers: [String : String] {
        switch self {
        case .withdraw:
            return [:]
        }
    }
}
