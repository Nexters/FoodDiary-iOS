//
//  LoginRequest.swift
//  Domain
//
//  Created by 강대훈 on 2/15/26.
//

import Foundation

/// 로그인 요청 정보를 담는 도메인 엔티티
public struct LoginRequest: Sendable {
    public let appVersion: String
    public let identityToken: String
    public let deviceId: String?
    public let osVersion: String
    public let fcmToken: String?
    public let notificationEnabled: Bool

    public init(
        appVersion: String,
        identityToken: String,
        deviceId: String?,
        osVersion: String,
        fcmToken: String?,
        notificationEnabled: Bool
    ) {
        self.appVersion = appVersion
        self.identityToken = identityToken
        self.deviceId = deviceId
        self.osVersion = osVersion
        self.fcmToken = fcmToken
        self.notificationEnabled = notificationEnabled
    }
}
