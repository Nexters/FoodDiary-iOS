//
//  InsightResponseDTO.swift
//  Data
//

import Domain
import Foundation

struct InsightResponseDTO: Decodable {
    let month: String
    let photoStats: PhotoStatsDTO
    let categoryStats: CategoryStatsDTO
    let topMenu: TopMenuDTO
    let diaryTimeStats: DiaryTimeStatsDTO
    let keywords: [String]

    enum CodingKeys: String, CodingKey {
        case month
        case photoStats = "photo_stats"
        case categoryStats = "category_stats"
        case topMenu = "top_menu"
        case diaryTimeStats = "diary_time_stats"
        case keywords
    }

    func toInsight() -> Insight {
        Insight(
            month: month,
            photoStats: photoStats.toEntity(),
            categoryStats: categoryStats.toEntity(),
            topMenu: topMenu.toEntity(),
            diaryTimeStats: diaryTimeStats.toEntity(),
            keywords: keywords
        )
    }
}

struct PhotoStatsDTO: Decodable {
    let currentMonthCount: Int
    let previousMonthCount: Int
    let changeRate: Double

    enum CodingKeys: String, CodingKey {
        case currentMonthCount = "current_month_count"
        case previousMonthCount = "previous_month_count"
        case changeRate = "change_rate"
    }

    func toEntity() -> PhotoStats {
        PhotoStats(
            currentMonthCount: currentMonthCount,
            previousMonthCount: previousMonthCount,
            changeRate: changeRate
        )
    }
}

struct CategoryStatsDTO: Decodable {
    let currentMonth: CategoryStatDTO
    let previousMonth: CategoryStatDTO

    enum CodingKeys: String, CodingKey {
        case currentMonth = "current_month"
        case previousMonth = "previous_month"
    }

    func toEntity() -> CategoryStats {
        CategoryStats(
            currentMonth: currentMonth.toEntity(),
            previousMonth: previousMonth.toEntity()
        )
    }
}

struct CategoryStatDTO: Decodable {
    let topCategory: String
    let count: Int

    enum CodingKeys: String, CodingKey {
        case topCategory = "top_category"
        case count
    }

    func toEntity() -> CategoryStat {
        CategoryStat(topCategory: topCategory, count: count)
    }
}

struct TopMenuDTO: Decodable {
    let name: String
    let count: Int

    func toEntity() -> TopMenu {
        TopMenu(name: name, count: count)
    }
}

struct DiaryTimeStatsDTO: Decodable {
    let mostActiveHour: Int
    let distribution: [HourCountDTO]

    enum CodingKeys: String, CodingKey {
        case mostActiveHour = "most_active_hour"
        case distribution
    }

    func toEntity() -> DiaryTimeStats {
        DiaryTimeStats(
            mostActiveHour: mostActiveHour,
            distribution: distribution.map { $0.toEntity() }
        )
    }
}

struct HourCountDTO: Decodable {
    let hour: Int
    let count: Int

    func toEntity() -> HourCount {
        HourCount(hour: hour, count: count)
    }
}
