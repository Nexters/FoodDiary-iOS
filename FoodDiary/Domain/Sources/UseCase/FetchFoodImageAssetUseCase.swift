//
//  FetchFoodImageAssetUseCase.swift
//  Domain
//
//  Created by Kai Lee on 1/20/26.
//

import Foundation

public struct FetchFoodImageAssetUseCase<Repository: FoodImageAssetRepository> {
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

    /// 인접 주간 사진 데이터를 백그라운드에서 미리 로드하여 캐시 워밍
    /// - Parameter date: 기준 날짜
    public func prefetch(for date: Date) {
        repository.prefetchFoodImageAssets(forAdjacentWeeksOf: date)
    }
}
