//
//  AuthEndpoint.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Domain
import Foundation

public enum AuthEndpoint {
    case login(idToken: String)
}

extension AuthEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }
        
        return url
    }
    
    public var path: String {
        switch self {
        case .login:
            "/auth/login"
        }
    }
    
    public var httpMethod: HTTPMethod {
        switch self {
        case .login:
            .post
        }
    }
    
    public var queryParameters: Encodable? {
        switch self {
        case .login:
            nil
        }
    }
    
    public var bodyParameters: Encodable? {
        switch self {
        case let .login(idToken):
            AuthRequestDTO(idToken: idToken, provider: .apple)
        }
    }
    
    public var headers: [String : String] {
        switch self {
        case .login:
            [:]
        }
    }
}
