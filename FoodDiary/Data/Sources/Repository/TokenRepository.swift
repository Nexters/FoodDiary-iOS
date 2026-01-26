//
//  TokenRepository.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Domain
import Foundation

public struct TokenRepositoryImpl<Manager: TokenManaging>: TokenRepository {
    // TODO: HTTPClient 사용
    let tokenManager: Manager

    public init(tokenManager: Manager) {
        self.tokenManager = tokenManager
    }

    public func save(_ identityToken: Data) async throws {
        // TODO: HTTPClient 호출해서 JWT 교환 -> JWT 저장
        print(String(data: identityToken, encoding: .utf8))
    }
}

public struct MockTokenRepository: TokenRepository {
    public init() {}

    public func save(_ identityToken: Data) async throws {
        print("MockToken")
    }
}
