//
//  LocalNotificationSchedulerTests.swift
//  Data
//

@testable import Data
import Foundation
import Testing
import UserNotifications

@Suite("LocalNotificationScheduler Tests")
struct LocalNotificationSchedulerTests {

    @Test("scheduleDailyReminder는 21:00 매일 반복되는 캘린더 트리거를 등록한다")
    func scheduleDailyReminder_addsCalendarTriggerAt21WithRepeats() async throws {
        let center = MockUserNotificationCenter()
        let sut = LocalNotificationScheduler(notificationCenter: center)

        await sut.scheduleDailyReminder(hour: 21, minute: 0)

        // 동일 identifier에 대해 기존 pending 제거 후 새로 add 되었는지
        #expect(center.removedIdentifiers.count == 1)
        #expect(center.removedIdentifiers.first == [LocalNotificationScheduler.dailyReminderIdentifier])

        #expect(center.addedRequests.count == 1)
        let request = try #require(center.addedRequests.first)

        #expect(request.identifier == LocalNotificationScheduler.dailyReminderIdentifier)

        // 매일 반복되는 캘린더 트리거인지
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.repeats == true)
        #expect(trigger.dateComponents.hour == 21)
        #expect(trigger.dateComponents.minute == 0)

        // 컨텐츠 검증 — 알림이 실제로 표시될 때 사용자가 보는 부분
        #expect(request.content.title == "오늘 먹은 음식, 기록해볼까요?")
        #expect(request.content.body == "하루가 끝나기 전에 오늘의 식사를 남겨보세요.")
        #expect(request.content.sound == .default)
        #expect(request.content.userInfo["notification_type"] as? String == "daily_reminder")
        // 분석 결과 푸시 분기와의 충돌 방지: is_local_notification 키는 들어가면 안 됨
        #expect(request.content.userInfo["is_local_notification"] == nil)
    }

    @Test("cancelDailyReminder는 등록된 리마인더를 제거하고 새로 추가하지 않는다")
    func cancelDailyReminder_removesPendingRequestsWithoutAdding() async {
        let center = MockUserNotificationCenter()
        let sut = LocalNotificationScheduler(notificationCenter: center)

        await sut.cancelDailyReminder()

        #expect(center.removedIdentifiers.count == 1)
        #expect(center.removedIdentifiers.first == [LocalNotificationScheduler.dailyReminderIdentifier])
        #expect(center.addedRequests.isEmpty)
    }

    @Test("scheduleDailyReminder를 두 번 호출해도 동일 identifier로 덮어쓰기된다 (idempotent)")
    func scheduleDailyReminder_calledTwice_isIdempotent() async {
        let center = MockUserNotificationCenter()
        let sut = LocalNotificationScheduler(notificationCenter: center)

        await sut.scheduleDailyReminder(hour: 21, minute: 0)
        await sut.scheduleDailyReminder(hour: 21, minute: 0)

        #expect(center.removedIdentifiers.count == 2)
        #expect(center.addedRequests.count == 2)
        #expect(center.addedRequests.allSatisfy {
            $0.identifier == LocalNotificationScheduler.dailyReminderIdentifier
        })
    }
}
