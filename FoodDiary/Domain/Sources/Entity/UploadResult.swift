//
//  UploadResult.swift
//  Domain
//

import Foundation

/// 서버 업로드 결과 (업로드 ID + 식사 타입)
public struct UploadResult: Sendable, Equatable {
    public let uploadId: String
    public let mealType: MealType

    public init(uploadId: String, mealType: MealType) {
        self.uploadId = uploadId
        self.mealType = mealType
    }
}
