//
//  MockFoodRecordRepository.swift
//  Domain
//

@testable import Domain
import Foundation

final class MockFoodRecordRepository: FoodRecordRepository, @unchecked Sendable {
    var recordsByDateToReturn: [Date: [FoodRecord]] = [:]
    var recordsToReturn: [FoodRecord] = []
    var uploadResultsToReturn: [UploadResult] = [
        UploadResult(uploadId: UUID().uuidString, mealType: .lunch)
    ]
    var shouldThrowError: Bool = false

    func fetchPhotoURLs(in dateRange: ClosedRange<Date>) async throws -> [Date : [URL]] {
        return [:]
    }

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

    func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> [UploadResult] {
        if shouldThrowError {
            throw MockError.testError
        }
        return uploadResultsToReturn
    }

    func updateRecord(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord {
        if shouldThrowError {
            throw MockError.testError
        }
        fatalError("Not implemented in mock")
    }

    func deleteRecord(id: String) async throws {
        if shouldThrowError {
            throw MockError.testError
        }
    }
}

enum MockError: Error {
    case testError
}
