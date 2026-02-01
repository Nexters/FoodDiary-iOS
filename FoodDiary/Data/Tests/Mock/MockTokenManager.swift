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
    private(set) var clearCallCount = 0
    private(set) var lastToken: String?
    var shouldThrow: Bool = false
    var shouldClearThrow: Bool = false
    
    func get() -> String? {
        return lastToken
    }
    
    func set(_ token: String) throws {
        setCallCount += 1
        lastToken = token
        
        if shouldThrow {
            lastToken = nil
            throw AppleLoginError.tokenPersistenceFailed
        }
    }
    
    func clear() throws {
        clearCallCount += 1
        
        if shouldClearThrow {
            throw AppleLoginError.tokenDecodingFailed
        }
        
        lastToken = nil
    }
}
