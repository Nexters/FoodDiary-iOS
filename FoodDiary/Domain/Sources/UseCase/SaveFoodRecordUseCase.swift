//
//  SaveFoodRecordUseCase.swift
//  Domain
//

import Foundation

/// 음식 기록 업로드 UseCase
public struct SaveFoodRecordUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    /// 음식 기록 업로드 실행
    /// - Parameter request: 생성 요청 데이터
    /// - Returns: 서버에서 발급한 업로드 ID
    public func execute(_ request: CreateFoodRecordRequest) async throws -> String {
        try await repository.uploadRecord(request)
    }
}
