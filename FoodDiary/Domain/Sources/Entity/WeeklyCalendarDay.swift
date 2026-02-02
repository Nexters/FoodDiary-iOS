//
//  WeeklyCalendarDay.swift
//  Domain
//

import Foundation

/// 주간 캘린더의 하루 데이터
public struct WeeklyCalendarDay: Sendable, Equatable {
    public let date: Date
    public let dayOfWeek: String
    public let dayNumber: String
    public let isToday: Bool
    public let isFuture: Bool
    public let records: [FoodRecord]

    public init(
        date: Date,
        dayOfWeek: String,
        dayNumber: String,
        isToday: Bool,
        isFuture: Bool,
        records: [FoodRecord]
    ) {
        self.date = date
        self.dayOfWeek = dayOfWeek
        self.dayNumber = dayNumber
        self.isToday = isToday
        self.isFuture = isFuture
        self.records = records
    }
}
