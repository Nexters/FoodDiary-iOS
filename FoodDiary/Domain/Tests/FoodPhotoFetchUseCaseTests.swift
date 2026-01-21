//
//  FoodPhotoFetchUseCaseTests.swift
//  Domain
//
//  Created by Kai Lee on 1/21/26.
//

@testable import Domain
import Photos
import Testing
import UIKit

@Suite("FoodPhotoFetchUseCase Tests")
struct FoodPhotoFetchUseCaseTests {
    @Test("빈 라이브러리에서 빈 결과 반환")
    func testEmptyLibraryReturnsEmpty() async throws {
        let mockLibrary = MockPhotoLibrary()
        let mockClassifier = MockFoodClassifier()
        let useCase = FoodPhotoFetchUseCase(
            photoLibrary: mockLibrary,
            foodClassifier: mockClassifier
        )

        let result = try await useCase.fetchFoodPhotos(
            from: Date(),
            to: nil
        )

        #expect(result.isEmpty)
    }

    @Test("음식 확률 순으로 정렬 (food 95% > food 51% > notFood 51% > notFood 95%)")
    func testSortedByFoodProbability() async throws {
        let mockLibrary = MockPhotoLibrary()
        let mockClassifier = MockFoodClassifier()

        let today = Date()
        mockLibrary.sectionsToReturn = [
            PhotoSection(date: today, photos: MockPHAsset.createMockAssets(count: 4))
        ]

        mockClassifier.classifyResults = [
            .notFood(confidence: 0.95), // foodProbability: 0.05
            .food(confidence: 0.51),    // foodProbability: 0.51
            .notFood(confidence: 0.51), // foodProbability: 0.49
            .food(confidence: 0.95)     // foodProbability: 0.95
        ]

        let useCase = FoodPhotoFetchUseCase(
            photoLibrary: mockLibrary,
            foodClassifier: mockClassifier
        )

        let result = try await useCase.fetchFoodPhotos(from: today, to: nil)

        #expect(result.count == 1)
        let photos = result[today]!
        #expect(photos.count == 4)
        #expect(photos[0].foodProbability ~== 0.95)
        #expect(photos[1].foodProbability ~== 0.51)
        #expect(photos[2].foodProbability ~== 0.49)
        #expect(photos[3].foodProbability ~== 0.05)
    }

    @Test("모든 사진이 결과에 포함됨")
    func testAllPhotosIncluded() async throws {
        let mockLibrary = MockPhotoLibrary()
        let mockClassifier = MockFoodClassifier()

        let today = Date()
        mockLibrary.sectionsToReturn = [
            PhotoSection(date: today, photos: MockPHAsset.createMockAssets(count: 3))
        ]

        mockClassifier.classifyResults = [
            .food(confidence: 0.9),
            .notFood(confidence: 0.8),
            .notFood(confidence: 0.95)
        ]

        let useCase = FoodPhotoFetchUseCase(
            photoLibrary: mockLibrary,
            foodClassifier: mockClassifier
        )

        let result = try await useCase.fetchFoodPhotos(from: today, to: nil)

        #expect(result.count == 1)
        #expect(result[today]?.count == 3)
    }

    @Test("여러 날짜 처리")
    func testMultipleDates() async throws {
        let mockLibrary = MockPhotoLibrary()
        let mockClassifier = MockFoodClassifier()

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        mockLibrary.sectionsToReturn = [
            PhotoSection(date: today, photos: MockPHAsset.createMockAssets(count: 2)),
            PhotoSection(date: yesterday, photos: MockPHAsset.createMockAssets(count: 2))
        ]

        mockClassifier.classifyResults = [
            .food(confidence: 0.9),
            .food(confidence: 0.85),
            .food(confidence: 0.8),
            .food(confidence: 0.95)
        ]

        let useCase = FoodPhotoFetchUseCase(
            photoLibrary: mockLibrary,
            foodClassifier: mockClassifier
        )

        let result = try await useCase.fetchFoodPhotos(from: yesterday, to: today)

        #expect(result.count == 2)
        #expect(result[today] != nil)
        #expect(result[yesterday] != nil)
    }
}

// MARK: - Test Helpers

private enum MockError: Error {
    case libraryError
    case imageLoadFailed
    case classifierError
}

private enum MockPHAsset {
    static func createMockAssets(count: Int) -> [PHAsset] {
        (0..<count).map { _ in PHAsset() }
    }
}

// MARK: - Float Approximate Equality

infix operator ~==: ComparisonPrecedence

private func ~== (lhs: Float, rhs: Float) -> Bool {
    abs(lhs - rhs) < 0.001
}
