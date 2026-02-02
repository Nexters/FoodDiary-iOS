//
//  MockFoodRecordRepository.swift
//  Domain
//

@testable import Domain
import Foundation

final class MockFoodRecordRepository: FoodRecordRepository, @unchecked Sendable {
    var recordsByDateToReturn: [Date: [FoodRecord]] = [:]
    var recordsToReturn: [FoodRecord] = []
    var savedRecord: FoodRecord?
    var shouldThrowError: Bool = false

    func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]] {
        if shouldThrowError {
            throw MockError.testError
        }
        return recordsByDateToReturn.filter { dateRange.contains($0.key) }
    }

    func fetchRecords(for date: Date) async throws -> [FoodRecord] {
        if shouldThrowError {
            throw MockError.testError
        }
        return recordsToReturn
    }

    func saveRecord(_ request: CreateFoodRecordRequest) async throws -> FoodRecord {
        if shouldThrowError {
            throw MockError.testError
        }
        let record = savedRecord ?? FoodRecord(
            id: UUID().uuidString,
            date: request.date,
            mealType: .lunch,
            genre: .etc,
            imageURLs: [],
            restaurantName: nil,
            address: nil,
            hashtags: [],
            createdAt: Date()
        )
        return record
    }
}

enum MockError: Error {
    case testError
}
