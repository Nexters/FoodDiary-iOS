//
//  MockNotificationAuthorizationProvider.swift
//  Domain
//

@testable import Domain
import Foundation

final class MockNotificationAuthorizationProvider: NotificationAuthorizationProviding, @unchecked Sendable {
    var isEnabledToReturn: Bool = true

    func isNotificationEnabled() async -> Bool {
        isEnabledToReturn
    }
}
