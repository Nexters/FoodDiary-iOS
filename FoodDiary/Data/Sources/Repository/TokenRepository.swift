//
//  TokenRepository.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Domain
import Foundation

public struct TokenRepositoryImpl<Manager: TokenManaging>: TokenRepository {
    let httpClient: HTTPClient<AuthEndpoint>
    let tokenManager: Manager

    public init(httpClient: HTTPClient<AuthEndpoint>, tokenManager: Manager) {
        self.httpClient = httpClient
        self.tokenManager = tokenManager
    }

    public func save(_ identityToken: Data) async throws -> LoginResult {
        if let token = String(data: identityToken, encoding: .utf8) {
            let response: AuthResponseDTO = try await httpClient.request(.login(idToken: token))
            try tokenManager.set(response.accessToken)
            return LoginResult(isFirst: response.isFirst)
        } else {
            throw NSError(domain: "Invalid Token", code: 0, userInfo: nil)
        }
    }
}

public struct MockTokenRepository: TokenRepository {
    public init() {}

    public func save(_ identityToken: Data) async throws -> LoginResult {
        throw AppleLoginError.tokenPersistenceFailed
    }
}
