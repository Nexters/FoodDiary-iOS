//
//  MockPendingFoodRecordRepository.swift
//  Domain
//

@testable import Domain
import Foundation

final class MockPendingFoodRecordRepository: PendingFoodRecordRepository, @unchecked Sendable {
    var recordsToReturn: [PendingFoodRecord] = []
    var deletedUploadIds: [String] = []
    var deletedDates: [Date] = []
    var shouldThrowError: Bool = false

    func fetchAll() async throws -> [PendingFoodRecord] {
        if shouldThrowError { throw MockError.testError }
        return recordsToReturn
    }

    func save(_ record: PendingFoodRecord) async throws {
        if shouldThrowError { throw MockError.testError }
        recordsToReturn.append(record)
    }

    func delete(byUploadIds uploadIds: [String]) async throws {
        if shouldThrowError { throw MockError.testError }
        deletedUploadIds.append(contentsOf: uploadIds)
        recordsToReturn.removeAll { uploadIds.contains($0.uploadId) }
    }

    func delete(byDate date: Date) async throws {
        if shouldThrowError { throw MockError.testError }
        deletedDates.append(date)
    }
}
