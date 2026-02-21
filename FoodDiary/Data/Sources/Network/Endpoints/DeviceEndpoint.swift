//
//  DeviceEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation
import Domain

public enum DeviceEndpoint {
    case me(request: UpdateDeviceNotificationRequest)
}

extension DeviceEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }
        
        return url
    }
    
    public var path: String {
        switch self {
        case .me:
            "/members/me/device"
        }
    }
    
    public var httpMethod: HTTPMethod {
        switch self {
        case .me:
            .post
        }
    }
    
    public var queryParameters: Encodable? {
        switch self {
        case .me:
            nil
        }
    }
    
    public var bodyParameters: HTTPBody {
        switch self {
        case let .me(request):
            return .json(
                DeviceUpsertRequestDTO(
                    appVersion: request.appVersion,
                    deviceId: request.deviceID,
                    deviceToken: request.deviceToken,
                    isActive: request.isActive,
                    osVersion: request.osVersion
                )
            )
        }
    }
    
    public var headers: [String : String] {
        switch self {
        case .me:
            return [:]
        }
    }
}
