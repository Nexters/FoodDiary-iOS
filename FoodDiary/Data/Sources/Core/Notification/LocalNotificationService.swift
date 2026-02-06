//
//  LocalNotificationService.swift
//  Data
//

import UserNotifications

public struct LocalNotificationService: Sendable {
    public init() {}

    public func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func sendRecordSavedNotification(restaurantName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "음식 기록 완료"
        content.body = restaurantName.map { "\($0) 기록이 저장되었어요!" }
            ?? "새로운 음식 기록이 저장되었어요!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    public func sendRecordFailedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "기록 저장 실패"
        content.body = "음식 기록 저장에 실패했어요. 다시 시도해주세요."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
