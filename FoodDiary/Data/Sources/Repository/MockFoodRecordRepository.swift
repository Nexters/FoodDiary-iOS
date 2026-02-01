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

    public func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]] {
        mockRecords.filter { dateRange.contains($0.key) }
    }

    public func fetchRecords(for date: Date) async throws -> [FoodRecord] {
        let startOfDay = calendar.startOfDay(for: date)
        return mockRecords[startOfDay] ?? []
    }

    // MARK: - Mock Data Setup

    private static let mockImageURL = URL(string: "https://mblogthumb-phinf.pstatic.net/MjAyNDExMjBfNzgg/MDAxNzMyMTAyNjU2Nzc5.-_dSylVBQ7k5rG6AxtNZ2H8_tAh2kOTjNsU1Ef2xQHog.v80D1-aXmFLEFMCz6vr_Vgao2AnJgPucdfGMI4dGAvwg.JPEG/IMG_7463.JPG?type=w800")!

    private func setupMockData() {
        let today = calendar.startOfDay(for: Date())

        // 오늘 기록
        if let todayLunch = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today),
           let todayDinner = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today) {
            mockRecords[today] = [
                FoodRecord(
                    id: UUID().uuidString,
                    date: today,
                    mealType: .lunch,
                    imageURLs: [Self.mockImageURL],
                    restaurantName: "맛있는 중화요리",
                    address: "서울시 강남구 테헤란로 123",
                    hashtags: ["양장피", "짜장면", "탕수육"],
                    createdAt: todayLunch
                ),
                FoodRecord(
                    id: UUID().uuidString,
                    date: today,
                    mealType: .dinner,
                    imageURLs: [Self.mockImageURL],
                    restaurantName: "스시오마카세",
                    address: "서울시 강남구 압구정로 456",
                    hashtags: ["오마카세", "스시", "사케"],
                    createdAt: todayDinner
                )
            ]
        }

        // 어제 기록
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           let yesterdayLunch = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: yesterday) {
            mockRecords[yesterday] = [
                FoodRecord(
                    id: UUID().uuidString,
                    date: yesterday,
                    mealType: .lunch,
                    imageURLs: [Self.mockImageURL],
                    restaurantName: "할머니 손칼국수",
                    address: "서울시 종로구 인사동길 12",
                    hashtags: ["칼국수", "만두", "김치"],
                    createdAt: yesterdayLunch
                )
            ]
        }

        // 3일 전 기록
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today),
           let breakfastTime = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: threeDaysAgo),
           let lateNightTime = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: threeDaysAgo) {
            mockRecords[threeDaysAgo] = [
                FoodRecord(
                    id: UUID().uuidString,
                    date: threeDaysAgo,
                    mealType: .breakfast,
                    imageURLs: [Self.mockImageURL],
                    restaurantName: "브런치 카페",
                    address: "서울시 마포구 연남동 123-45",
                    hashtags: ["브런치", "에그베네딕트", "아메리카노"],
                    createdAt: breakfastTime
                ),
                FoodRecord(
                    id: UUID().uuidString,
                    date: threeDaysAgo,
                    mealType: .lateNight,
                    imageURLs: [Self.mockImageURL],
                    restaurantName: "포장마차",
                    address: "서울시 마포구 홍대입구역",
                    hashtags: ["떡볶이", "순대", "오뎅"],
                    createdAt: lateNightTime
                )
            ]
        }
    }
}
