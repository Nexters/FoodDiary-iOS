//
//  PendingFoodRecord.swift
//  Domain
//

import UIKit

/// 분석 대기 중인 음식 기록 (서버 응답 전)
public struct PendingFoodRecord: Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let representativeImage: UIImage
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        date: Date,
        representativeImage: UIImage,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.representativeImage = representativeImage
        self.createdAt = createdAt
    }
}
