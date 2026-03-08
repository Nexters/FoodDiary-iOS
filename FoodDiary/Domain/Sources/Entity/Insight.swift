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

    public init(
        month: String,
        photoStats: PhotoStats,
        categoryStats: CategoryStats,
        topMenu: TopMenu,
        diaryTimeStats: DiaryTimeStats,
        keywords: [String]
    ) {
        self.month = month
        self.photoStats = photoStats
        self.categoryStats = categoryStats
        self.topMenu = topMenu
        self.diaryTimeStats = diaryTimeStats
        self.keywords = keywords
    }
}

public struct PhotoStats: Equatable, Sendable {
    public let currentMonthCount: Int
    public let previousMonthCount: Int
    public let changeRate: Double

    public init(currentMonthCount: Int, previousMonthCount: Int, changeRate: Double) {
        self.currentMonthCount = currentMonthCount
        self.previousMonthCount = previousMonthCount
        self.changeRate = changeRate
    }
}

public struct CategoryStats: Equatable, Sendable {
    public let currentMonth: CategoryStat
    public let previousMonth: CategoryStat

    public init(currentMonth: CategoryStat, previousMonth: CategoryStat) {
        self.currentMonth = currentMonth
        self.previousMonth = previousMonth
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

public struct TopMenu: Equatable, Sendable {
    public let name: String
    public let count: Int

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

public struct DiaryTimeStats: Equatable, Sendable {
    public let mostActiveHour: Int
    public let distribution: [HourCount]

    public init(mostActiveHour: Int, distribution: [HourCount]) {
        self.mostActiveHour = mostActiveHour
        self.distribution = distribution
    }
}

public struct HourCount: Equatable, Sendable {
    public let hour: Int
    public let count: Int

    public init(hour: Int, count: Int) {
        self.hour = hour
        self.count = count
    }
}
