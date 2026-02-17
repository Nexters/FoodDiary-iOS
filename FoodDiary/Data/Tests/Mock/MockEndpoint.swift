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
    case multipart(MultipartFormData)
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
        case .multipart:
            return "/photos/batch-upload"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .minimal:
            return .get
        case .full, .multipart:
            return .post
        }
    }

    var queryParameters: Encodable? {
        switch self {
        case .minimal, .multipart:
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
        case let .multipart(formData):
            return .multipart(formData)
        }
    }

    var headers: [String: String] {
        switch self {
        case .minimal, .multipart:
            return [:]
        case .full:
            return [
                "X-Test-Header": "kang"
            ]
        }
    }
}

