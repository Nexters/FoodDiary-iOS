//
//  PendingFoodRecord.swift
//  Domain
//

import UIKit

/// 분석 대기 중인 음식 기록 (서버 업로드 완료, AI 분석 대기 중)
public struct PendingFoodRecord: Identifiable, Equatable {
    public let id: String
    /// 서버에서 받은 업로드 ID (Remote Push로 결과 매칭 시 사용)
    public let uploadId: String
    public let date: Date
    public let representativeImage: UIImage
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        uploadId: String,
        date: Date,
        representativeImage: UIImage,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.uploadId = uploadId
        self.date = date
        self.representativeImage = representativeImage
        self.createdAt = createdAt
    }
}
