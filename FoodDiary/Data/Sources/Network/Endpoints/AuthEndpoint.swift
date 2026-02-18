//
//  AuthEndpoint.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Domain
import Foundation

public enum AuthEndpoint {
    case login(request: LoginRequest)
    case verify
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
        case .verify:
            "/auth/verify"
        }
    }
    
    public var httpMethod: HTTPMethod {
        switch self {
        case .login:
            .post
        case .verify:
            .get
        }
    }
    
    public var queryParameters: Encodable? {
        switch self {
        case .login:
            nil
        case .verify:
            nil
        }
    }
    
    public var bodyParameters: HTTPBody {
        switch self {
        case let .login(request):
            return .json(
                AuthRequestDTO(
                    appVersion: request.appVersion,
                    deviceId: request.deviceId,
                    deviceToken: request.fcmToken,
                    idToken: request.identityToken,
                    isActive: request.notificationEnabled,
                    osVersion: request.osVersion,
                    provider: .apple
                )
            )
        case .verify:
            return .none
        }
    }
    
    public var headers: [String : String] {
        switch self {
        case .login, .verify:
            [:]
        }
    }
}
