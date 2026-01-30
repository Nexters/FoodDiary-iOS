//
//  TokenRepository.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Domain
import Foundation

public struct TokenRepositoryImpl<Manager: TokenManaging, Client: HTTPClienting>: TokenRepository where Client.Target == AuthEndpoint {
    let httpClient: Client
    let tokenManager: Manager

    public init(httpClient: Client, tokenManager: Manager) {
        self.httpClient = httpClient
        self.tokenManager = tokenManager
    }

    public func save(_ identityToken: Data) async throws -> LoginResult {
        if let token = String(data: identityToken, encoding: .utf8) {
            let response: AuthResponseDTO = try await httpClient.request(.login(idToken: token))
            try tokenManager.set(response.accessToken)
            return LoginResult(isFirst: response.isFirst)
        } else {
            throw AppleLoginError.tokenPersistenceFailed
        }
    }
    
    public func deleteToken() throws {
        try tokenManager.clear()
    }
}
