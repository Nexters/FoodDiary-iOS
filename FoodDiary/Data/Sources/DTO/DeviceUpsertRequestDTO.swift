//
//  DeviceUpsertRequestDTO.swift
//  Data
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation
import Domain

public struct DeviceUpsertRequestDTO: Encodable {
    let appVersion: String
    let deviceId: String?
    let deviceToken: String?
    let isActive: Bool
    let osVersion: String

    public init(
        appVersion: String,
        deviceId: String?,
        deviceToken: String?,
        isActive: Bool,
        osVersion: String,
    ) {
        self.appVersion = appVersion
        self.deviceId = deviceId
        self.deviceToken = deviceToken
        self.isActive = isActive
        self.osVersion = osVersion
    }

    private enum CodingKeys: String, CodingKey {
        case appVersion = "app_version"
        case deviceId = "device_id"
        case deviceToken = "device_token"
        case isActive = "is_active"
        case osVersion = "os_version"
    }
}
