//
//  SaveFoodRecordUseCase.swift
//  Domain
//

import Foundation

/// 음식 기록 저장 UseCase
public struct SaveFoodRecordUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    /// 음식 기록 저장 실행
    /// - Parameter request: 생성 요청 데이터
    /// - Returns: 서버에서 생성된 FoodRecord
    public func execute(_ request: CreateFoodRecordRequest) async throws -> FoodRecord {
        try await repository.saveRecord(request)
    }
}
