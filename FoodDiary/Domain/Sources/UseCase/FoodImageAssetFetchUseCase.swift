//
//  FoodImageAssetFetchUseCase.swift
//  Domain
//
//  Created by Kai Lee on 1/20/26.
//

import Foundation

public struct FoodImageAssetFetchUseCase<Repository: FoodImageAssetRepository> {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(
        from startDate: Date,
        to endDate: Date?,
        priority: TaskPriority = .utility
    ) async throws -> [Date: [FoodImageAsset<Repository.Asset>]] {
        try await Task(priority: priority) {
            try await repository.fetchFoodImageAssets(from: startDate, to: endDate)
        }.value
    }
}
