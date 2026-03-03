//
//  NotificationAuthorizationProvider.swift
//  Data
//
//  Created by 강대훈 on 2/15/26.
//

import UserNotifications
import Domain

/// UNUserNotificationCenter를 사용한 알림 권한 상태 제공 구현체
public final class NotificationAuthorizationProvider: NotificationAuthorizationProviding {
    private let notificationCenter: UNUserNotificationCenter

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    public func isNotificationEnabled() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
