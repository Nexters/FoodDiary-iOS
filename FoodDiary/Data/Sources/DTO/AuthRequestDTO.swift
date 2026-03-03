//
//  AuthRequestDTO.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Foundation
import Domain

public struct AuthRequestDTO: Encodable {
    let appVersion: String
    let deviceId: String?
    let deviceToken: String?
    let idToken: String
    let isActive: Bool
    let osVersion: String
    let provider: SocialAuth

    public init(
        appVersion: String,
        deviceId: String?,
        deviceToken: String?,
        idToken: String,
        isActive: Bool,
        osVersion: String,
        provider: SocialAuth
    ) {
        self.appVersion = appVersion
        self.deviceId = deviceId
        self.deviceToken = deviceToken
        self.idToken = idToken
        self.isActive = isActive
        self.osVersion = osVersion
        self.provider = provider
    }

    private enum CodingKeys: String, CodingKey {
        case appVersion = "app_version"
        case deviceId = "device_id"
        case deviceToken = "device_token"
        case idToken = "id_token"
        case isActive = "is_active"
        case osVersion = "os_version"
        case provider
    }
}
