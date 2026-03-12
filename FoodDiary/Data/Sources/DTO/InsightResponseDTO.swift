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
    let keywordStats: [KeywordStatDTO]
    let locationStats: [LocationStatDTO]

    enum CodingKeys: String, CodingKey {
        case month
        case photoStats = "photo_stats"
        case categoryStats = "category_stats"
        case topMenu = "top_menu"
        case diaryTimeStats = "diary_time_stats"
        case keywords
        case keywordStats = "keyword_stats"
        case locationStats = "location_stats"
    }

    func toInsight() -> Insight {
        Insight(
            month: month,
            photoStats: photoStats.toEntity(),
            categoryStats: categoryStats.toEntity(),
            topMenu: topMenu.toEntity(),
            diaryTimeStats: diaryTimeStats.toEntity(),
            keywords: keywords,
            keywordStats: keywordStats.map { $0.toEntity() },
            locationStats: locationStats.map { $0.toEntity() }
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
            changeRate: Int(changeRate)
        )
    }
}

struct CategoryStatsDTO: Decodable {
    let currentMonth: CategoryStatDTO
    let previousMonth: CategoryStatDTO
    let currentMonthCounts: CategoryCountsDTO

    enum CodingKeys: String, CodingKey {
        case currentMonth = "current_month"
        case previousMonth = "previous_month"
        case currentMonthCounts = "current_month_counts"
    }

    func toEntity() -> CategoryStats {
        CategoryStats(
            currentMonth: currentMonth.toEntity(),
            previousMonth: previousMonth.toEntity(),
            currentMonthCounts: currentMonthCounts.toEntity()
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

struct CategoryCountsDTO: Decodable {
    let chinese: Int
    let etc: Int
    let homeCooked: Int
    let japanese: Int
    let korean: Int
    let western: Int

    enum CodingKeys: String, CodingKey {
        case chinese
        case etc
        case homeCooked = "home_cooked"
        case japanese
        case korean
        case western
    }

    func toEntity() -> CategoryCounts {
        CategoryCounts(
            chinese: chinese,
            etc: etc,
            homeCooked: homeCooked,
            japanese: japanese,
            korean: korean,
            western: western
        )
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
    let mostActiveTime: String
    let distribution: [TimeCountDTO]

    enum CodingKeys: String, CodingKey {
        case mostActiveTime = "most_active_time"
        case distribution
    }

    func toEntity() -> DiaryTimeStats {
        DiaryTimeStats(
            mostActiveTime: mostActiveTime,
            distribution: distribution.map { $0.toEntity() }
        )
    }
}

struct TimeCountDTO: Decodable {
    let time: String
    let count: Int

    func toEntity() -> TimeCount {
        TimeCount(time: time, count: count)
    }
}

struct KeywordStatDTO: Decodable {
    let keyword: String
    let count: Int

    func toEntity() -> KeywordStat {
        KeywordStat(keyword: keyword, count: count)
    }
}

struct LocationStatDTO: Decodable {
    let dong: String
    let count: Int

    func toEntity() -> LocationStat {
        LocationStat(dong: dong, count: count)
    }
}
