//
//  LoadWeeklyCalendarDataUseCase.swift
//  Domain
//

import Foundation

/// 주간 캘린더 데이터 로딩을 담당하는 UseCase
public struct LoadWeeklyCalendarDataUseCase<
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
    private let fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>
    private let fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>

    public init(
        calendar: Calendar,
        fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>,
        fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    ) {
        self.calendar = calendar
        self.fetchWeeklyCalendarUseCase = fetchWeeklyCalendarUseCase
        self.fetchFoodImageAssetUseCase = fetchFoodImageAssetUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
    }

    /// 주간 데이터 로드
    public func loadWeekData(for date: Date) async throws -> WeekData {
        fetchFoodImageAssetUseCase.prefetch(for: date)
        let weekDays = try await fetchWeeklyCalendarUseCase.execute(for: date)
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

        let records = try await fetchFoodRecordsUseCase.execute(for: date)

        return DateData(
            photos: photosByDate[startOfDay] ?? [],
            records: records,
            startOfDay: startOfDay
        )
    }
}
