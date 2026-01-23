//
//  FoodPhotoFetchUseCaseTests.swift
//  Domain
//
//  Created by Kai Lee on 1/21/26.
//

@testable import Domain
import Foundation
import Testing

@Suite("FoodPhotoFetchUseCase Tests")
struct FoodPhotoFetchUseCaseTests {
    @Test("빈 결과 반환")
    func testEmptyResultReturnsEmpty() async throws {
        let mockRepository = MockFoodPhotoAlbumRepository()
        let useCase = FoodPhotoFetchUseCase(repository: mockRepository)

        let result = try await useCase.fetchFoodPhotos(
            from: Date(),
            to: nil
        )

        #expect(result.isEmpty)
    }

    @Test("Repository 결과를 그대로 반환")
    func testReturnsRepositoryResult() async throws {
        let mockRepository = MockFoodPhotoAlbumRepository()

        let today = Date()
        let photos = createMockFoodPhotos(count: 4, probabilities: [0.95, 0.51, 0.49, 0.05])
        mockRepository.resultToReturn = [today: photos]

        let useCase = FoodPhotoFetchUseCase(repository: mockRepository)

        let result = try await useCase.fetchFoodPhotos(from: today, to: nil)

        #expect(result.count == 1)
        #expect(result[today]?.count == 4)
    }

    @Test("여러 날짜 처리")
    func testMultipleDates() async throws {
        let mockRepository = MockFoodPhotoAlbumRepository()

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        mockRepository.resultToReturn = [
            today: createMockFoodPhotos(startIndex: 0, count: 2, probabilities: [0.9, 0.85]),
            yesterday: createMockFoodPhotos(startIndex: 2, count: 2, probabilities: [0.95, 0.8])
        ]

        let useCase = FoodPhotoFetchUseCase(repository: mockRepository)

        let result = try await useCase.fetchFoodPhotos(from: yesterday, to: today)

        #expect(result.count == 2)
        #expect(result[today] != nil)
        #expect(result[yesterday] != nil)
    }
}

// MARK: - Test Helpers

private func createMockFoodPhotos(
    startIndex: Int = 0,
    count: Int,
    probabilities: [Float]
) -> [FoodPhoto<MockImageAssetable>] {
    (0..<count).map { index in
        FoodPhoto(
            imageAsset: MockImageAssetable(
                id: "photo_\(startIndex + index)",
                creationDate: Date()
            ),
            foodProbability: probabilities[index]
        )
    }
}
