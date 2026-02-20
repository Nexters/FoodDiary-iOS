//
//  UpdateDeviceNotificationRequest.swift
//  Domain
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation

/// 디바이스 알림 설정 업데이트 요청 정보를 담는 도메인 엔티티
public struct UpdateDeviceNotificationRequest: Sendable {
    public let appVersion: String
    public let deviceID: String?
    public let deviceToken: String?
    public let isActive: Bool
    public let osVersion: String

    public init(
        appVersion: String,
        deviceID: String?,
        deviceToken: String?,
        isActive: Bool,
        osVersion: String
    ) {
        self.appVersion = appVersion
        self.deviceID = deviceID
        self.deviceToken = deviceToken
        self.isActive = isActive
        self.osVersion = osVersion
    }
}
