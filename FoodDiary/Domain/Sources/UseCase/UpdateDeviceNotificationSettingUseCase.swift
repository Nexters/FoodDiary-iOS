//
//  UpdateDeviceNotificationSettingUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation

public struct UpdateDeviceNotificationSettingUseCase<Repository: DeviceRepository> {
    private let repository: Repository
    private let notificationAuthorizationProvider: NotificationAuthorizationProviding
    private let pushTokenProvider: PushTokenStoring
    private let appVersion: String
    private let deviceID: String?
    private let osVersion: String

    public init(
        repository: Repository,
        notificationAuthorizationProvider: NotificationAuthorizationProviding,
        pushTokenProvider: PushTokenStoring,
        appVersion: String,
        deviceID: String?,
        osVersion: String
    ) {
        self.repository = repository
        self.notificationAuthorizationProvider = notificationAuthorizationProvider
        self.pushTokenProvider = pushTokenProvider
        self.appVersion = appVersion
        self.deviceID = deviceID
        self.osVersion = osVersion
    }

    /// 디바이스의 알림 설정 상태를 서버에 업데이트합니다.
    ///
    /// 현재 알림 권한 상태를 조회하여 서버에 전송합니다.
    public func execute() async throws {
        let isActive = await notificationAuthorizationProvider.isNotificationEnabled()

        let request = UpdateDeviceNotificationRequest(
            appVersion: appVersion,
            deviceID: deviceID,
            deviceToken: pushTokenProvider.get(),
            isActive: isActive,
            osVersion: osVersion
        )

        try await repository.updateNotificationSetting(request)
    }
}
