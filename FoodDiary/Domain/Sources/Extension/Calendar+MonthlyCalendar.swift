//
//  Calendar+MonthlyCalendar.swift
//  Domain
//

import Foundation

public extension Calendar {
    /// 월간 캘린더 표시 기간 계산 (이전/다음 달 포함)
    func monthlyCalendarPeriod(for date: Date) -> DateInterval {
        var calendar = self
        calendar.firstWeekday = 2  // 월요일 시작

        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return DateInterval(start: date, end: date)
        }

        let leadingCount = (firstWeekday - calendar.firstWeekday + 7) % 7

        // 이전 달 포함 시작일
        let startDate = calendar.date(
            byAdding: .day,
            value: -leadingCount,
            to: monthInterval.start
        ) ?? monthInterval.start

        // 다음 달 포함 종료일 계산
        let daysFromStartToMonthEnd = calendar.dateComponents(
            [.day],
            from: startDate,
            to: monthInterval.end
        ).day ?? 0

        let remainder = daysFromStartToMonthEnd % 7
        let trailingCount = remainder > 0 ? 7 - remainder : 0

        let endDate = calendar.date(
            byAdding: .day,
            value: trailingCount,
            to: monthInterval.end
        ) ?? monthInterval.end

        return DateInterval(start: startDate, end: endDate)
    }
}
