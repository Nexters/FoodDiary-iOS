//
//  MockFoodPhotoAlbumRepository.swift
//  Domain
//
//  Created by Kai Lee on 1/21/26.
//

@testable import Domain
import Foundation

final class MockFoodPhotoAlbumRepository: FoodPhotoRepository, @unchecked Sendable {
    typealias Asset = MockImageAssetable

    var resultToReturn: [Date: [FoodPhoto<MockImageAssetable>]] = [:]

    func fetchFoodPhotos(from startDate: Date, to endDate: Date?) async throws -> [Date: [FoodPhoto<MockImageAssetable>]] {
        resultToReturn
    }
}
