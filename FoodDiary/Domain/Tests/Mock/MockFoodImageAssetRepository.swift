//
//  MockFoodImageAssetRepository.swift
//  Domain
//
//  Created by Kai Lee on 1/21/26.
//

@testable import Domain
import Foundation

final class MockFoodImageAssetRepository: FoodImageAssetRepository, @unchecked Sendable {
    typealias Asset = MockImageAssetable

    var resultToReturn: [Date: [FoodImageAsset<MockImageAssetable>]] = [:]

    func fetchFoodImageAssets(from startDate: Date, to endDate: Date?) async throws -> [Date: [FoodImageAsset<MockImageAssetable>]] {
        resultToReturn
    }
}
