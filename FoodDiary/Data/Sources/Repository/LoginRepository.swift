//
//  LoginRepository.swift
//  Data
//
//  Created by 강대훈 on 1/25/26.
//

import Domain
import Foundation

public struct LoginRepositoryImpl: LoginRepository {
    // TODO: HTTPClient 사용
    let tokenManager: TokenManaging
    
    public init(tokenManager: TokenManaging) {
        self.tokenManager = tokenManager
    }
    
    public func sendIdentityToken(_ token: Data) async throws {
        // TODO: HTTPClient 호출해서 JWT 교환 -> JWT 저장
        print(String(data: token, encoding: .utf8))
    }
}

public struct MockLoginRepository: LoginRepository {
    public init() {}
    
    public func sendIdentityToken(_ identityToken: Data) async throws {
        print("MockToken")
    }
}
