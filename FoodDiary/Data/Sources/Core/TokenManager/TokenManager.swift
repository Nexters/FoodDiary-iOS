//
//  TokenProvider.swift
//  Data
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation
import Domain

public struct TokenManager: TokenManaging {
    private let keychainService: KeychainService
    private let tokenKey = "access_token"
    
    public init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    
    public func get() -> String? {
        keychainService.load(key: tokenKey)
    }
    
    public func set(_ token: String) throws {
        if !keychainService.save(key: tokenKey, value: token) {
            throw AppleLoginError.tokenPersistenceFailed
        }
    }
    
    public func clear() throws {
        if !keychainService.delete(key: tokenKey) {
            throw AppleLoginError.tokenDecodingFailed
        }
    }
}
