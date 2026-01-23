//
//  LoginRepository.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public protocol LoginRepository {
    func sendIdentityToken(_ identityToken: Data) async throws
}

// TODO: Data로 이동
public struct LoginRepositoryImpl: LoginRepository {
    // TODO: HTTPClient 사용
    let tokenManager: TokenManaging
    
    public init(tokenManager: TokenManaging = TokenManager()) {
        self.tokenManager = tokenManager
    }
    
    public func sendIdentityToken(_ token: Data) async throws {
        // TODO: HTTPClient 호출해서 JWT 교환 -> JWT 저장
        print(String(data: token, encoding: .utf8))
    }
}
