//
//  FetchFoodRecordsUseCaseTests.swift
//  Domain
//

@testable import Domain
import Foundation
import Testing

@Suite("FetchFoodRecordsUseCase Tests")
struct FetchFoodRecordsUseCaseTests {

    @Test("Repository 결과를 그대로 반환")
    func testReturnsRepositoryResult() async throws {
        let mockRepository = MockFoodRecordRepository()
        let today = Date()

        let records = [
            FoodRecord(id: "1", date: today, mealType: .lunch, genre: .korean, imageURLs: [], createdAt: today),
            FoodRecord(id: "2", date: today, mealType: .dinner, genre: .western, imageURLs: [], createdAt: today)
        ]
        mockRepository.recordsToReturn = records

        let useCase = FetchFoodRecordsUseCase(repository: mockRepository)
        let result = try await useCase.execute(for: today)

        #expect(result.count == 2)
        #expect(result[0].id == "1")
        #expect(result[1].id == "2")
    }

    @Test("빈 결과 반환")
    func testEmptyResultReturnsEmpty() async throws {
        let mockRepository = MockFoodRecordRepository()
        mockRepository.recordsToReturn = []

        let useCase = FetchFoodRecordsUseCase(repository: mockRepository)
        let result = try await useCase.execute(for: Date())

        #expect(result.isEmpty)
    }

    @Test("에러 발생 시 throw")
    func testThrowsOnError() async {
        let mockRepository = MockFoodRecordRepository()
        mockRepository.shouldThrowError = true

        let useCase = FetchFoodRecordsUseCase(repository: mockRepository)

        await #expect(throws: MockError.self) {
            try await useCase.execute(for: Date())
        }
    }
}
