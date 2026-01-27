//
//  MockTokenManager.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

@testable import Data
import Domain

final class MockTokenManager: TokenManaging {
    private(set) var setCallCount = 0
    private(set) var lastToken: String?
    
    func get() -> String? {
        return lastToken
    }
    
    func set(_ token: String) throws {
        setCallCount += 1
        lastToken = token
    }
}
