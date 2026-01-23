//
//  FoodPhotoFetchUseCase.swift
//  Domain
//
//  Created by Kai Lee on 1/20/26.
//

import Foundation

public struct FoodPhotoFetchUseCase<Repository: FoodPhotoRepository> {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func fetchFoodPhotos(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodPhoto<Repository.Asset>]] {
        try await repository.fetchFoodPhotos(from: startDate, to: endDate)
    }
}
