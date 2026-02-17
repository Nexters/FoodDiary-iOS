//
//  PushTokenStorage.swift
//  Data
//
//  Created by 강대훈 on 2/15/26.
//

import Foundation
import Domain

public final class InMemoryPushTokenStorage: PushTokenStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var token: String?

    public init() {}

    public func get() -> String? {
        lock.withLock { token }
    }

    public func set(_ token: String) {
        lock.withLock { self.token = token }
    }

    public func clear() {
        lock.withLock { self.token = nil }
    }
}
