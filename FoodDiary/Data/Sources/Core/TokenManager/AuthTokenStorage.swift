//
//  AuthTokenStorage.swift
//  Data
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation
import Domain

/// Keychain을 사용한 인증 토큰 저장소 구현체
public struct AuthTokenStorage<Service: KeychainServicing>: AuthTokenStoring {
    private let keychainService: Service
    private let tokenKey = "access_token"

    public init(keychainService: Service) {
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
