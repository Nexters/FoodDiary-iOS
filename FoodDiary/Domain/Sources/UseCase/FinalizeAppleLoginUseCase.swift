//
//  FinalizeAppleLoginUseCase.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public enum AppleLoginError: Error {
    case tokenPersistenceFailed
    case tokenDecodingFailed
}

public struct FinalizeAppleLoginUseCase {
    private let authRepository: AuthRepository
    private let deviceInfoProvider: DeviceInfoProviding
    private let pushTokenStorage: PushTokenStoring
    private let notificationAuthorizationProvider: NotificationAuthorizationProviding

    public init(
        authRepository: AuthRepository,
        deviceInfoProvider: DeviceInfoProviding,
        pushTokenStorage: PushTokenStoring,
        notificationAuthorizationProvider: NotificationAuthorizationProviding
    ) {
        self.authRepository = authRepository
        self.deviceInfoProvider = deviceInfoProvider
        self.pushTokenStorage = pushTokenStorage
        self.notificationAuthorizationProvider = notificationAuthorizationProvider
    }

    public func execute(_ appleIdentityToken: String) async throws -> LoginResult {
        let deviceId = deviceInfoProvider.deviceId
        let osVersion = deviceInfoProvider.osVersion
        let fcmToken = pushTokenStorage.get()
        let notificationEnabled = await notificationAuthorizationProvider.isNotificationEnabled()

        // LoginRequest 도메인 모델 생성
        let loginRequest = LoginRequest(
            appVersion: "1.0.0",
            identityToken: appleIdentityToken,
            deviceId: deviceId,
            osVersion: osVersion,
            fcmToken: fcmToken,
            notificationEnabled: notificationEnabled
        )

        // 로그인 요청
        return try await authRepository.login(loginRequest)
    }
}
