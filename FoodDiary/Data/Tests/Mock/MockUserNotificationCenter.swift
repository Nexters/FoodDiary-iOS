//
//  MockUserNotificationCenter.swift
//  Data
//

@testable import Data
import UserNotifications

final class MockUserNotificationCenter: UserNotificationCentering, @unchecked Sendable {
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedIdentifiers: [[String]] = []
    var addError: Error?

    func add(_ request: UNNotificationRequest) async throws {
        if let addError {
            throw addError
        }
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(identifiers)
    }
}
