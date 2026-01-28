//
//  FetchWeeklyCalendarUseCase.swift
//  Domain
//

import Foundation

/// 주간 캘린더 데이터 생성 UseCase
public struct FetchWeeklyCalendarUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository
    private let calendar: Calendar

    public init(repository: Repository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    /// 특정 날짜가 포함된 주의 캘린더 데이터 반환
    /// - Parameter date: 기준 날짜
    /// - Returns: 7일간의 WeeklyCalendarDay 배열
    public func execute(for date: Date) async throws -> [WeeklyCalendarDay] {
        let (weekStart, weekEnd) = calculateWeekRange(for: date)
        let weekDates = generateWeekDates(from: weekStart)
        let recordedDates = try await repository.fetchRecordedDates(in: weekStart...weekEnd)

        return weekDates.map { dayDate in
            let startOfDay = calendar.startOfDay(for: dayDate)
            return WeeklyCalendarDay(
                date: dayDate,
                dayOfWeek: formatDayOfWeek(dayDate),
                dayNumber: formatDayNumber(dayDate),
                isToday: calendar.isDateInToday(dayDate),
                hasRecord: recordedDates.contains(startOfDay)
            )
        }
    }

    /// 이전 주 날짜 계산
    public func previousWeek(from date: Date) -> Date {
        calendar.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
    }

    /// 다음 주 날짜 계산
    public func nextWeek(from date: Date) -> Date {
        calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
    }

    /// 월 텍스트 포맷팅 (예: "1월")
    public func formatMonthText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: date)
    }

    // MARK: - Private Helpers

    private func calculateWeekRange(for date: Date) -> (start: Date, end: Date) {
        // 일요일 시작 기준
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = weekday - 1
        let weekStart = calendar.date(
            byAdding: .day,
            value: -daysToSubtract,
            to: calendar.startOfDay(for: date)
        )!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        return (weekStart, weekEnd)
    }

    private func generateWeekDates(from weekStart: Date) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func formatDayNumber(_ date: Date) -> String {
        String(format: "%02d", calendar.component(.day, from: date))
    }
}
