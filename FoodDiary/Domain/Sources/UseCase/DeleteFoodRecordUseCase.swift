//
//  DeleteFoodRecordUseCase.swift
//  Domain
//

import Foundation

public struct DeleteFoodRecordUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(id: String) async throws {
        try await repository.deleteRecord(id: id)
    }
}
