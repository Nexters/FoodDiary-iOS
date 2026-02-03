//
//  MonthlyCalendarDay.swift
//  Domain
//

import Foundation

/// 월간 캘린더의 하루 데이터
public struct MonthlyCalendarDay: Sendable, Equatable, Hashable {
    public let id: String
    public let date: Date
    public let dayNumber: String
    public let isCurrentMonth: Bool
    public let isToday: Bool
    public let records: [FoodRecord]

    public init(
        date: Date,
        dayNumber: String,
        isCurrentMonth: Bool,
        isToday: Bool,
        records: [FoodRecord]
    ) {
        self.id = date.timeIntervalSince1970.description
        self.date = date
        self.dayNumber = dayNumber
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.records = records
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
