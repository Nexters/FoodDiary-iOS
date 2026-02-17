//
//  MockEndpoint.swift
//  Core
//
//  Created by 강대훈 on 1/18/26.
//

import Foundation
@testable import Data

enum MockEndpoint {
    case minimal
    case full
}

extension MockEndpoint: Requestable {
    var baseURL: String {
        "https://api.example.com"
    }

    var path: String {
        switch self {
        case .minimal:
            return "/health"
        case .full:
            return "/users"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .minimal:
            return .get
        case .full:
            return .post
        }
    }

    var queryParameters: Encodable? {
        switch self {
        case .minimal:
            return nil
        case .full:
            return ["tests": "1"]
        }
    }

    var bodyParameters: HTTPBody {
        switch self {
        case .minimal:
            return .none
        case .full:
            return .json(MockBodyDTO(name: "Kang", age: 999))
        }
    }

    var headers: [String: String] {
        switch self {
        case .minimal:
            return [:]
        case .full:
            return [
                "X-Test-Header": "kang"
            ]
        }
    }
}

