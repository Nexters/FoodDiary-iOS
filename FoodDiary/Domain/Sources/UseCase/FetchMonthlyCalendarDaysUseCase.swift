//
//  FetchMonthlyCalendarDaysUseCase.swift
//  Domain
//

import Foundation

/// 월간 캘린더 데이터 조회 UseCase
public struct FetchMonthlyCalendarDaysUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(for period: DateInterval, currentMonth: Date) async throws -> [MonthlyCalendarDay] {
        let calendar = Calendar.current

        // 캘린더 날짜 배열 생성
        let monthDays = generateCalendarDays(for: period, currentMonth: currentMonth, calendar: calendar)

        // 음식 기록 조회
        let recordsByDate = try await repository.fetchRecords(in: period.start...period.end)

        // 날짜와 음식 기록 매핑
        return monthDays.map { day in
            let dayStart = calendar.startOfDay(for: day.date)
            let records = recordsByDate[dayStart] ?? []
            return MonthlyCalendarDay(
                date: day.date,
                dayNumber: day.dayNumber,
                isCurrentMonth: day.isCurrentMonth,
                isToday: day.isToday,
                records: records
            )
        }
    }

    // MARK: - Private Methods

    private func generateCalendarDays(
        for period: DateInterval,
        currentMonth: Date,
        calendar: Calendar
    ) -> [MonthlyCalendarDay] {
        let today = calendar.startOfDay(for: Date())
        let currentMonthInterval = calendar.dateInterval(of: .month, for: currentMonth)

        var days: [MonthlyCalendarDay] = []
        var currentDate = period.start

        while currentDate < period.end {
            let isCurrentMonth = currentMonthInterval?.contains(currentDate) ?? false
            days.append(MonthlyCalendarDay(
                date: currentDate,
                dayNumber: calendar.component(.day, from: currentDate),
                isCurrentMonth: isCurrentMonth,
                isToday: calendar.isDate(currentDate, inSameDayAs: today),
                records: []
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return days
    }
}
