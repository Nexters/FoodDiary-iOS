//
//  LoadWeeklyRecordUseCase.swift
//  Domain
//

import Foundation

/// 주간 캘린더 데이터 로딩을 담당하는 UseCase
public struct LoadWeeklyRecordUseCase<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository
>: Sendable {
    public struct WeekData: Sendable {
        public let weekDays: [WeeklyCalendarDay]
        public let monthText: String

        public init(weekDays: [WeeklyCalendarDay], monthText: String) {
            self.weekDays = weekDays
            self.monthText = monthText
        }
    }

    public struct DateData: Sendable {
        public let photos: [FoodImageAsset<AssetRepo.Asset>]
        public let records: [FoodRecord]
        public let startOfDay: Date

        public init(photos: [FoodImageAsset<AssetRepo.Asset>], records: [FoodRecord], startOfDay: Date) {
            self.photos = photos
            self.records = records
            self.startOfDay = startOfDay
        }
    }

    private let calendar: Calendar
    private let recordRepository: RecordRepo
    private let fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>

    public init(
        calendar: Calendar,
        recordRepository: RecordRepo,
        fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>
    ) {
        self.calendar = calendar
        self.recordRepository = recordRepository
        self.fetchFoodImageAssetUseCase = fetchFoodImageAssetUseCase
    }

    /// 주간 데이터 로드
    public func loadWeekData(
        for date: Date,
        locale: Locale = Locale(identifier: "ko_KR")
    ) async throws -> WeekData {
        fetchFoodImageAssetUseCase.prefetch(for: date)

        let (weekStart, weekEnd) = calendar.weekRange(for: date)
        let weekDates = calendar.weekDates(from: weekStart)
        let recordsByDate = try await recordRepository.fetchRecords(in: weekStart...weekEnd)

        let today = calendar.startOfDay(for: Date())
        let weekDays = weekDates.map { dayDate in
            let startOfDay = calendar.startOfDay(for: dayDate)
            return WeeklyCalendarDay(
                date: dayDate,
                dayOfWeek: dayDate.formatDayOfWeek(locale: locale),
                dayNumber: dayDate.formatDayNumber(calendar: calendar),
                isToday: calendar.isDateInToday(dayDate),
                isFuture: startOfDay > today,
                records: recordsByDate[startOfDay] ?? []
            )
        }

        let monthText = date.formatMonthText()
        return WeekData(weekDays: weekDays, monthText: monthText)
    }

    /// 특정 날짜 데이터 로드
    public func loadDateData(for date: Date) async throws -> DateData {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)

        let photosByDate = try await fetchFoodImageAssetUseCase.execute(
            from: startOfDay,
            to: endOfDay
        )

        let records = try await recordRepository.fetchRecords(for: date)

        return DateData(
            photos: photosByDate[startOfDay] ?? [],
            records: records,
            startOfDay: startOfDay
        )
    }
}
