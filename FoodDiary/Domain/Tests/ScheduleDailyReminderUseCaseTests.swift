//
//  ScheduleDailyReminderUseCaseTests.swift
//  Domain
//

@testable import Domain
import Foundation
import Testing

@Suite("ScheduleDailyReminderUseCase Tests")
struct ScheduleDailyReminderUseCaseTests {

    @Test("알림 권한이 켜져 있으면 매일 21:00 리마인더가 등록된다")
    func whenAuthorizationEnabled_schedulesDailyReminderAt21() async {
        let scheduler = MockLocalNotificationScheduler()
        let authProvider = MockNotificationAuthorizationProvider()
        authProvider.isEnabledToReturn = true

        let sut = ScheduleDailyReminderUseCase(
            scheduler: scheduler,
            authorizationProvider: authProvider
        )

        await sut.execute()

        #expect(scheduler.scheduleCallCount == 1)
        #expect(scheduler.cancelCallCount == 0)
        #expect(scheduler.lastScheduledHour == 21)
        #expect(scheduler.lastScheduledMinute == 0)
    }

    @Test("알림 권한이 꺼져 있으면 리마인더가 등록되지 않고 취소된다")
    func whenAuthorizationDisabled_cancelsReminderInsteadOfScheduling() async {
        let scheduler = MockLocalNotificationScheduler()
        let authProvider = MockNotificationAuthorizationProvider()
        authProvider.isEnabledToReturn = false

        let sut = ScheduleDailyReminderUseCase(
            scheduler: scheduler,
            authorizationProvider: authProvider
        )

        await sut.execute()

        #expect(scheduler.scheduleCallCount == 0)
        #expect(scheduler.cancelCallCount == 1)
        #expect(scheduler.lastScheduledHour == nil)
        #expect(scheduler.lastScheduledMinute == nil)
    }
}
