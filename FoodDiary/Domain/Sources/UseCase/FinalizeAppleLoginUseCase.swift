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
    private let deviceId: String
    private let osVersion: String
    private let pushTokenStorage: PushTokenStoring
    private let notificationAuthorizationProvider: NotificationAuthorizationProviding
    private let initialLaunchStorage: InitialLaunchStoring

    public init(
        authRepository: AuthRepository,
        deviceId: String,
        osVersion: String,
        pushTokenStorage: PushTokenStoring,
        notificationAuthorizationProvider: NotificationAuthorizationProviding,
        initialLaunchStorage: InitialLaunchStoring
    ) {
        self.authRepository = authRepository
        self.deviceId = deviceId
        self.osVersion = osVersion
        self.pushTokenStorage = pushTokenStorage
        self.notificationAuthorizationProvider = notificationAuthorizationProvider
        self.initialLaunchStorage = initialLaunchStorage
    }

    public func execute(_ appleIdentityToken: String) async throws -> LoginResult {
        let fcmToken = pushTokenStorage.get()
        let notificationEnabled = await notificationAuthorizationProvider.isNotificationEnabled()

        let loginRequest = LoginRequest(
            appVersion: "1.0.0",
            identityToken: appleIdentityToken,
            deviceId: deviceId,
            osVersion: osVersion,
            fcmToken: fcmToken,
            notificationEnabled: notificationEnabled
        )

        let result = try await authRepository.login(loginRequest)
        initialLaunchStorage.set()
        return result
    }
}
