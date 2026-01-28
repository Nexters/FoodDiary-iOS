//
//  MockFoodRecordRepository.swift
//  Data
//

import Domain
import Foundation

/// Mock 구현: 서버 API 대신 사용
public final class MockFoodRecordRepository: FoodRecordRepository, @unchecked Sendable {
    private var mockRecords: [Date: [FoodRecord]] = [:]
    private let calendar = Calendar.current

    public init() {
        setupMockData()
    }

    public func fetchRecordedDates(in dateRange: ClosedRange<Date>) async throws -> Set<Date> {
        Set(
            mockRecords.keys.filter { date in
                dateRange.contains(date)
            }
        )
    }

    public func fetchRecords(for date: Date) async throws -> [FoodRecord] {
        let startOfDay = calendar.startOfDay(for: date)
        return mockRecords[startOfDay] ?? []
    }

    // MARK: - Mock Data Setup

    private func setupMockData() {
        let today = calendar.startOfDay(for: Date())

        // 오늘, 어제, 3일 전에 기록이 있다고 가정
        [0, -1, -3].forEach { dayOffset in
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                mockRecords[date] = [
                    FoodRecord(
                        id: UUID().uuidString,
                        date: date,
                        imageURLs: [],
                        createdAt: date
                    )
                ]
            }
        }
    }
}
