//
//  NicknameStorage.swift
//  Data
//
//  Created by 강대훈 on 2/24/26.
//

import Domain
import Foundation

public final class NicknameStorage: NicknameStoring {
    private let lock = NSLock()
    private var nickname: String?

    public init() {}

    public func get() -> String? {
        lock.withLock { nickname }
    }

    public func set(_ nickname: String) {
        lock.withLock { self.nickname = nickname }
    }
}
