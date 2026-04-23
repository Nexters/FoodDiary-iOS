//
//  DeleteFoodRecordUseCase.swift
//  Domain
//

import Foundation

public struct DeleteFoodRecordUseCase: Sendable {
    private let repository: any FoodRecordRepository

    public init(repository: any FoodRecordRepository) {
        self.repository = repository
    }

    public func execute(id: String) async throws {
        try await repository.deleteRecord(id: id)
    }
}
