//
//  Calendar+Extension.swift
//  Domain
//

import Foundation

public extension Calendar {
    /// 이전 주 날짜 계산
    func previousWeek(from date: Date) -> Date {
        self.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
    }

    /// 다음 주 날짜 계산
    func nextWeek(from date: Date) -> Date {
        self.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
    }

    /// 주간 날짜 범위 계산 (일요일 시작 기준)
    func weekRange(for date: Date) -> (start: Date, end: Date) {
        let weekday = component(.weekday, from: date)
        let daysToSubtract = weekday - 1
        let weekStart = self.date(
            byAdding: .day,
            value: -daysToSubtract,
            to: startOfDay(for: date)
        )!
        let weekEnd = self.date(byAdding: .day, value: 6, to: weekStart)!
        return (weekStart, weekEnd)
    }

    /// 주간 날짜 배열 생성 (7일)
    func weekDates(from weekStart: Date) -> [Date] {
        (0..<7).compactMap { self.date(byAdding: .day, value: $0, to: weekStart) }
    }
}

public extension Date {
    /// 월 텍스트 포맷팅 (예: "1월")
    func formatMonthText(locale: Locale = Locale(identifier: "ko_KR")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "M월"
        return formatter.string(from: self)
    }

    /// 요일 포맷팅 (예: "월", "화")
    func formatDayOfWeek(locale: Locale = Locale(identifier: "ko_KR")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }

    /// 일자 2자리 포맷팅 (예: "01", "15")
    func formatDayNumber(calendar: Calendar) -> String {
        String(format: "%02d", calendar.component(.day, from: self))
    }
}
