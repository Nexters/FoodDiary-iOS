//
//  UpdateFoodRecordUseCase.swift
//  Domain
//

import Foundation

public struct UpdateFoodRecordUseCase: Sendable {
    private let repository: any FoodRecordRepository

    public init(repository: any FoodRecordRepository) {
        self.repository = repository
    }

    public func execute(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord {
        try await repository.updateRecord(request)
    }
}
