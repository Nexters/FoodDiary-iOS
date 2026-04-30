//
//  LocalNotificationScheduling.swift
//  Domain
//

import Foundation

public protocol LocalNotificationScheduling: Sendable {
    func scheduleDailyReminder(hour: Int, minute: Int) async
    func cancelDailyReminder() async
}
