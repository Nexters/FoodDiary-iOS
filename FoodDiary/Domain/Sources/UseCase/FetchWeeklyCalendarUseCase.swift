//
//  FetchWeeklyCalendarUseCase.swift
//  Domain
//

import Foundation

/// 주간 캘린더 데이터 생성 UseCase
public struct FetchWeeklyCalendarUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository
    private let calendar: Calendar

    public init(
        repository: Repository,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }

    /// 특정 날짜가 포함된 주의 캘린더 데이터 반환
    /// - Parameters:
    ///   - date: 기준 날짜
    ///   - locale: 요일 포맷팅에 사용할 로케일
    /// - Returns: 7일간의 WeeklyCalendarDay 배열
    public func execute(
        for date: Date,
        locale: Locale = Locale(identifier: "ko_KR")
    ) async throws -> [WeeklyCalendarDay] {
        let (weekStart, weekEnd) = calendar.weekRange(for: date)
        let weekDates = calendar.weekDates(from: weekStart)
        let recordsByDate = try await repository.fetchRecords(in: weekStart...weekEnd)

        return weekDates.map { dayDate in
            let startOfDay = calendar.startOfDay(for: dayDate)
            return WeeklyCalendarDay(
                date: dayDate,
                dayOfWeek: dayDate.formatDayOfWeek(locale: locale),
                dayNumber: dayDate.formatDayNumber(calendar: calendar),
                isToday: calendar.isDateInToday(dayDate),
                records: recordsByDate[startOfDay] ?? []
            )
        }
    }
}
