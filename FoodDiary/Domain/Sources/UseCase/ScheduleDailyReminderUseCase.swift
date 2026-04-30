//
//  ScheduleDailyReminderUseCase.swift
//  Domain
//

import Foundation

public struct ScheduleDailyReminderUseCase: Sendable {
    private let scheduler: any LocalNotificationScheduling
    private let authorizationProvider: any NotificationAuthorizationProviding

    public init(
        scheduler: any LocalNotificationScheduling,
        authorizationProvider: any NotificationAuthorizationProviding
    ) {
        self.scheduler = scheduler
        self.authorizationProvider = authorizationProvider
    }

    public func execute() async {
        if await authorizationProvider.isNotificationEnabled() {
            await scheduler.scheduleDailyReminder(hour: 21, minute: 0)
        } else {
            await scheduler.cancelDailyReminder()
        }
    }
}
