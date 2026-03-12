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
    let diaryTimeStats: DiaryTimeStatsDTO
    let locationStats: [LocationStatDTO]
    let tagStats: [KeywordStatDTO]
    let weeklyStats: WeeklyStatsDTO

    enum CodingKeys: String, CodingKey {
        case month
        case photoStats = "photo_stats"
        case categoryStats = "category_stats"
        case diaryTimeStats = "diary_time_stats"
        case locationStats = "location_stats"
        case tagStats = "tag_stats"
        case weeklyStats = "weekly_stats"
    }

    func toInsight() -> Insight {
        Insight(
            month: month,
            photoStats: photoStats.toEntity(),
            categoryStats: categoryStats.toEntity(),
            diaryTimeStats: diaryTimeStats.toEntity(),
            locationStats: locationStats.map { $0.toEntity() },
            tagStats: tagStats.map { $0.toEntity() },
            weeklyStats: weeklyStats.toEntity()
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

struct WeeklyStatsDTO: Decodable {
    let mostActiveWeek: Int
    let weeklyCounts: [WeekCountDTO]

    enum CodingKeys: String, CodingKey {
        case mostActiveWeek = "most_active_week"
        case weeklyCounts = "weekly_counts"
    }

    func toEntity() -> WeeklyStats {
        WeeklyStats(
            mostActiveWeek: mostActiveWeek,
            weeklyCounts: weeklyCounts.map { $0.toEntity() }
        )
    }
}

struct WeekCountDTO: Decodable {
    let week: Int
    let count: Int

    func toEntity() -> WeekCount {
        WeekCount(week: week, count: count)
    }
}
