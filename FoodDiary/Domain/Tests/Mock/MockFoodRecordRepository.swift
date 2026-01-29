//
//  MockFoodRecordRepository.swift
//  Domain
//

@testable import Domain
import Foundation

final class MockFoodRecordRepository: FoodRecordRepository, @unchecked Sendable {
    var recordedDatesToReturn: Set<Date> = []
    var recordsToReturn: [FoodRecord] = []
    var shouldThrowError: Bool = false

    func fetchRecordedDates(in dateRange: ClosedRange<Date>) async throws -> Set<Date> {
        if shouldThrowError {
            throw MockError.testError
        }
        return recordedDatesToReturn.filter { dateRange.contains($0) }
    }

    func fetchRecords(for date: Date) async throws -> [FoodRecord] {
        if shouldThrowError {
            throw MockError.testError
        }
        return recordsToReturn
    }
}

enum MockError: Error {
    case testError
}
