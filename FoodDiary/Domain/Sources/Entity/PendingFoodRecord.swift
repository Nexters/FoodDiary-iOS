//
//  PendingFoodRecord.swift
//  Domain
//

import Foundation

/// 분석 대기 중인 음식 기록 (서버 업로드 완료, AI 분석 대기 중)
public struct PendingFoodRecord: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    /// 서버에서 받은 업로드 ID (Remote Push로 결과 매칭 시 사용)
    public let uploadId: String
    public let mealType: MealType
    public let date: Date
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        uploadId: String,
        mealType: MealType,
        date: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.uploadId = uploadId
        self.mealType = mealType
        self.date = date
        self.createdAt = createdAt
    }
}
