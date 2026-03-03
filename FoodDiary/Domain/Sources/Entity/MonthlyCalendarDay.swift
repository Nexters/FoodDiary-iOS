//
//  MonthlyCalendarDay.swift
//  Domain
//

import Foundation

/// 월간 캘린더의 하루 데이터
public struct MonthlyCalendarDay: Sendable, Equatable, Hashable {
    public let id: String
    public let date: Date
    public let dayNumber: Int
    public let isCurrentMonth: Bool
    public let isToday: Bool
    public let imageURLs: [URL]

    public init(
        date: Date,
        dayNumber: Int,
        isCurrentMonth: Bool,
        isToday: Bool,
        imageURLs: [URL]
    ) {
        self.id = date.timeIntervalSince1970.description
        self.date = date
        self.dayNumber = dayNumber
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.imageURLs = imageURLs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
