//
//  FetchMonthlyCalendarDaysUseCase.swift
//  Domain
//

import Foundation

/// 월간 캘린더 데이터 조회 UseCase
public struct FetchMonthlyCalendarDaysUseCase: Sendable {
    private let repository: any FoodRecordRepository

    public init(repository: any FoodRecordRepository) {
        self.repository = repository
    }

    public func execute(for period: DateInterval, currentMonth: Date) -> AsyncThrowingStream<[MonthlyCalendarDay], Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await recordsByDate in repository.fetchPhotoURLs(in: period.start...period.end) {
                        let days = generateCalendarDays(
                            for: period,
                            currentMonth: currentMonth,
                            calendar: .current,
                            recordsByDate: recordsByDate
                        )
                        continuation.yield(days)
                    }
                    prefetchAdjacentMonths(for: currentMonth)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func prefetchAdjacentMonths(for date: Date) {
        let calendar = Calendar.current
        let neighbors = [-1, 1].compactMap { calendar.date(byAdding: .month, value: $0, to: date) }
        for neighbor in neighbors {
            Task { await prefetch(neighbor) }
        }
    }

    private func prefetch(_ date: Date) async {
        let period = Calendar.current.monthlyCalendarPeriod(for: date)
        do {
            for try await _ in repository.fetchPhotoURLs(in: period.start...period.end) {}
        } catch {}
    }

    // MARK: - Private Methods

    private func generateCalendarDays(
        for period: DateInterval,
        currentMonth: Date,
        calendar: Calendar,
        recordsByDate: [Date: [URL]]
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
            let photoURLs = recordsByDate[dayStart] ?? []

            days.append(MonthlyCalendarDay(
                date: currentDate,
                dayNumber: calendar.component(.day, from: currentDate),
                isCurrentMonth: isCurrentMonth,
                isToday: calendar.isDate(currentDate, inSameDayAs: today),
                imageURLs: photoURLs
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return days
    }
}
