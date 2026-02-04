//
//  FoodRecord.swift
//  Domain
//

import Foundation

/// 서버에서 받아온 음식 기록 정보
public struct FoodRecord: Identifiable, Equatable, Sendable {
    public let id: String
    public let date: Date
    public let mealType: MealType
    public let genre: FoodGenre
    public let imageURLs: [URL]
    public let restaurantName: String?
    public let address: String?
    public let hashtags: [String]
    public let createdAt: Date

    public init(
        id: String,
        date: Date,
        mealType: MealType,
        genre: FoodGenre,
        imageURLs: [URL],
        restaurantName: String? = nil,
        address: String? = nil,
        hashtags: [String] = [],
        createdAt: Date
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.genre = genre
        self.imageURLs = imageURLs
        self.restaurantName = restaurantName
        self.address = address
        self.hashtags = hashtags
        self.createdAt = createdAt
    }

    /// 포맷된 시간 (예: "오후 1시 12분")
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h시 m분"
        return formatter.string(from: createdAt)
    }
}
