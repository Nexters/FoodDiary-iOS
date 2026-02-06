//
//  WeeklyCalendarDataLoader.swift
//  Presentation
//

import Data
import Domain
import Foundation

struct WeeklyCalendarDataLoader<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository
> {
    struct WeekData {
        let weekDays: [WeeklyCalendarDay]
        let monthText: String
    }

    struct DateData {
        let photos: [FoodImageAsset<AssetRepo.Asset>]
        let records: [FoodRecord]
        let startOfDay: Date
    }

    private let calendar: Calendar
    private let fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>
    private let fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>

    init(
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

    func loadWeekData(for date: Date) async throws -> WeekData {
        fetchFoodImageAssetUseCase.prefetch(for: date)
        let weekDays = try await fetchWeeklyCalendarUseCase.execute(for: date)
        let monthText = date.formatMonthText()
        return WeekData(weekDays: weekDays, monthText: monthText)
    }

    func loadDateData(for date: Date) async throws -> DateData {
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
