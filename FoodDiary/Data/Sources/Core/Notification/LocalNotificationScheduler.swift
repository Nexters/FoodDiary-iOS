//
//  LocalNotificationScheduler.swift
//  Data
//

import UserNotifications
import Domain

/// 테스트 가능성을 위한 내부 추상화. 실제 구현은 UNUserNotificationCenter
protocol UserNotificationCentering: Sendable {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCentering {}

public final class LocalNotificationScheduler: LocalNotificationScheduling {
    static let dailyReminderIdentifier = "daily_reminder"

    private let notificationCenter: any UserNotificationCentering

    public convenience init() {
        self.init(notificationCenter: UNUserNotificationCenter.current())
    }

    init(notificationCenter: any UserNotificationCentering) {
        self.notificationCenter = notificationCenter
    }

    public func scheduleDailyReminder(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "오늘 먹은 음식, 기록해볼까요?"
        content.body = "하루가 끝나기 전에 오늘의 식사를 남겨보세요."
        content.sound = .default
        content.userInfo = ["notification_type": "daily_reminder"]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Self.dailyReminderIdentifier]
        )

        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        try? await notificationCenter.add(request)
        print("[LocalNotification] 매일 \(hour):\(String(format: "%02d", minute)) 리마인더 등록 완료")
    }

    public func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Self.dailyReminderIdentifier]
        )
        print("[LocalNotification] 매일 리마인더 취소 완료")
    }
}
