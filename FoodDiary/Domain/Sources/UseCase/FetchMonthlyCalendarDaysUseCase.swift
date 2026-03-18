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
        let recordsByDate = try await repository.fetchPhotoURLs(in: period.start...period.end)

        prefetchAdjacentMonths(for: currentMonth)

        // 캘린더 날짜 배열 생성 (records 포함)
        return generateCalendarDays(
            for: period,
            currentMonth: currentMonth,
            calendar: calendar,
            recordsByDate: recordsByDate
        )
    }

    private func prefetchAdjacentMonths(for date: Date) {
        let calendar = Calendar.current
        let neighbors = [-1, 1].compactMap { calendar.date(byAdding: .month, value: $0, to: date) }
        for neighbor in neighbors {
            Task { await prefetch(neighbor) }
        }
    }

    private func prefetch(_ date: Date) async {
        let label = date.formatMonthText()
        let period = Calendar.current.monthlyCalendarPeriod(for: date)
        print("[Prefetch] 시작: \(label)")
        do {
            let urls = try await repository.fetchPhotoURLs(in: period.start...period.end)
            print("[Prefetch] 완료: \(label) — \(urls.count)개 URL")
        } catch {
            print("[Prefetch] 실패: \(label) — \(error)")
        }
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
