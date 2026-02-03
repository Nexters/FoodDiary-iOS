//
//  FetchMonthlyCalendarUseCase.swift
//  Domain
//

import Foundation

/// 월간 캘린더 데이터 생성 UseCase
public struct FetchMonthlyCalendarUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(
        for monthDays: [MonthlyCalendarDay]
    ) async throws -> [MonthlyCalendarDay] {
        guard let firstDay = monthDays.first?.date,
              let lastDay = monthDays.last?.date
        else {
            return monthDays
        }

        let recordsByDate = try await repository.fetchRecords(in: firstDay...lastDay)

        return monthDays.map { day in
            let dayStart = Calendar.current.startOfDay(for: day.date)
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
}
