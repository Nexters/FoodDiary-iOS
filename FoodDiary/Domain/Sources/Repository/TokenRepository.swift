//
//  TokenRepository.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public protocol TokenRepository {
    func save(_ identityToken: Data) async throws
}

public struct TokenRepositoryImpl: TokenRepository {
    // TODO: HTTPClient 사용
    let tokenManager: TokenManaging
    
    public init(tokenManager: TokenManaging = TokenManager()) {
        self.tokenManager = tokenManager
    }
    
    public func save(_ identityToken: Data) async throws {
        // TODO: HTTPClient 호출해서 JWT 교환 -> JWT 저장
        print(String(data: identityToken, encoding: .utf8))
    }
}
