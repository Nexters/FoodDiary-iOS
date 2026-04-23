//
//  FetchFoodRecordsUseCase.swift
//  Domain
//

import Foundation

/// 특정 날짜의 음식 기록 조회 UseCase
public struct FetchFoodRecordsUseCase: Sendable {
    private let repository: any FoodRecordRepository

    public init(repository: any FoodRecordRepository) {
        self.repository = repository
    }

    /// 특정 날짜의 기록 조회
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 음식 기록 배열
    public func execute(for date: Date) async throws -> [FoodRecord] {
        try await repository.fetchRecords(for: date)
    }
}
