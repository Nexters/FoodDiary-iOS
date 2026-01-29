//
//  FoodRecord.swift
//  Domain
//

import Foundation

/// 서버에서 받아온 음식 기록 정보
public struct FoodRecord: Sendable, Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let imageURLs: [URL]
    public let createdAt: Date

    public init(
        id: String,
        date: Date,
        imageURLs: [URL],
        createdAt: Date
    ) {
        self.id = id
        self.date = date
        self.imageURLs = imageURLs
        self.createdAt = createdAt
    }
}

extension Array: Equatable where Element == FoodRecord {}
