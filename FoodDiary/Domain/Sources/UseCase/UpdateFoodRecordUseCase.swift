//
//  UpdateFoodRecordUseCase.swift
//  Domain
//

import Foundation

public struct UpdateFoodRecordUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord {
        try await repository.updateRecord(request)
    }
}
