//
//  Insight.swift
//  Domain
//

import Foundation

public struct Insight: Equatable, Sendable {
    public let month: String
    public let photoStats: PhotoStats
    public let categoryStats: CategoryStats
    public let topMenu: TopMenu
    public let diaryTimeStats: DiaryTimeStats
    public let keywords: [String]
    public let keywordStats: [KeywordStat]
    public let locationStats: [LocationStat]

    public init(
        month: String,
        photoStats: PhotoStats,
        categoryStats: CategoryStats,
        topMenu: TopMenu,
        diaryTimeStats: DiaryTimeStats,
        keywords: [String],
        keywordStats: [KeywordStat],
        locationStats: [LocationStat]
    ) {
        self.month = month
        self.photoStats = photoStats
        self.categoryStats = categoryStats
        self.topMenu = topMenu
        self.diaryTimeStats = diaryTimeStats
        self.keywords = keywords
        self.keywordStats = keywordStats
        self.locationStats = locationStats
    }
}

public struct PhotoStats: Equatable, Sendable {
    public let currentMonthCount: Int
    public let previousMonthCount: Int
    public let changeRate: Int

    public init(currentMonthCount: Int, previousMonthCount: Int, changeRate: Int) {
        self.currentMonthCount = currentMonthCount
        self.previousMonthCount = previousMonthCount
        self.changeRate = changeRate
    }
}

public struct CategoryStats: Equatable, Sendable {
    public let currentMonth: CategoryStat
    public let previousMonth: CategoryStat
    public let currentMonthCounts: CategoryCounts

    public init(currentMonth: CategoryStat, previousMonth: CategoryStat, currentMonthCounts: CategoryCounts) {
        self.currentMonth = currentMonth
        self.previousMonth = previousMonth
        self.currentMonthCounts = currentMonthCounts
    }
}

public struct CategoryStat: Equatable, Sendable {
    public let topCategory: String
    public let count: Int

    public init(topCategory: String, count: Int) {
        self.topCategory = topCategory
        self.count = count
    }
}

public struct CategoryCounts: Equatable, Sendable {
    public let chinese: Int
    public let etc: Int
    public let homeCooked: Int
    public let japanese: Int
    public let korean: Int
    public let western: Int

    public init(chinese: Int, etc: Int, homeCooked: Int, japanese: Int, korean: Int, western: Int) {
        self.chinese = chinese
        self.etc = etc
        self.homeCooked = homeCooked
        self.japanese = japanese
        self.korean = korean
        self.western = western
    }
}

public struct TopMenu: Equatable, Sendable {
    public let name: String
    public let count: Int

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

public struct DiaryTimeStats: Equatable, Sendable {
    public let mostActiveTime: String
    public let distribution: [TimeCount]

    public init(mostActiveTime: String, distribution: [TimeCount]) {
        self.mostActiveTime = mostActiveTime
        self.distribution = distribution
    }
}

public struct TimeCount: Equatable, Sendable {
    public let time: String
    public let count: Int

    public init(time: String, count: Int) {
        self.time = time
        self.count = count
    }
}

public struct KeywordStat: Equatable, Sendable {
    public let keyword: String
    public let count: Int

    public init(keyword: String, count: Int) {
        self.keyword = keyword
        self.count = count
    }
}

public struct LocationStat: Equatable, Sendable {
    public let dong: String
    public let count: Int

    public init(dong: String, count: Int) {
        self.dong = dong
        self.count = count
    }
}
