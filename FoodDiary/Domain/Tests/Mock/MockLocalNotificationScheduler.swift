//
//  MockLocalNotificationScheduler.swift
//  Domain
//

@testable import Domain
import Foundation

final class MockLocalNotificationScheduler: LocalNotificationScheduling, @unchecked Sendable {
    private(set) var scheduleCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var lastScheduledHour: Int?
    private(set) var lastScheduledMinute: Int?

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        scheduleCallCount += 1
        lastScheduledHour = hour
        lastScheduledMinute = minute
    }

    func cancelDailyReminder() async {
        cancelCallCount += 1
    }
}
