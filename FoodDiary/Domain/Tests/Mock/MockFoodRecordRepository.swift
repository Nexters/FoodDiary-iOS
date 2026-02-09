//
//  MockFoodRecordRepository.swift
//  Domain
//

@testable import Domain
import Foundation

final class MockFoodRecordRepository: FoodRecordRepository, @unchecked Sendable {
    var recordsByDateToReturn: [Date: [FoodRecord]] = [:]
    var recordsToReturn: [FoodRecord] = []
    var uploadIdToReturn: String = UUID().uuidString
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

    func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> String {
        if shouldThrowError {
            throw MockError.testError
        }
        return uploadIdToReturn
    }
}

enum MockError: Error {
    case testError
}
