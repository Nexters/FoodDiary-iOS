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
        let calendar = Calendar.seoul
        let recordsByDate = try await repository.fetchRecords(in: period.start...period.end)

        // 캘린더 날짜 배열 생성 (records 포함)
        return generateCalendarDays(
            for: period,
            currentMonth: currentMonth,
            calendar: calendar,
            recordsByDate: recordsByDate
        )
    }

    // MARK: - Private Methods

    private func generateCalendarDays(
        for period: DateInterval,
        currentMonth: Date,
        calendar: Calendar,
        recordsByDate: [Date: [FoodRecord]]
    ) -> [MonthlyCalendarDay] {
        let today = calendar.startOfDay(for: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)

        var days: [MonthlyCalendarDay] = []
        var currentDate = period.start

        while currentDate < period.end {
            let dateComponents = calendar.dateComponents([.year, .month], from: currentDate)
            let isCurrentMonth = dateComponents.year == currentMonthComponents.year &&
                                 dateComponents.month == currentMonthComponents.month

            let dayStart = calendar.startOfDay(for: currentDate)
            let records = recordsByDate[dayStart] ?? []

            days.append(MonthlyCalendarDay(
                date: currentDate,
                dayNumber: calendar.component(.day, from: currentDate),
                isCurrentMonth: isCurrentMonth,
                isToday: calendar.isDate(currentDate, inSameDayAs: today),
                records: records
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return days
    }
}
