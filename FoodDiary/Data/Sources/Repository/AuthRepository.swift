//
//  AuthRepository.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Domain
import Foundation

public struct AuthRepositoryImpl<Manager: TokenManaging, Client: HTTPClienting>: AuthRepository {
    let httpClient: Client
    let tokenManager: Manager

    public init(httpClient: Client, tokenManager: Manager) {
        self.httpClient = httpClient
        self.tokenManager = tokenManager
    }

    public func login(_ identityToken: Data) async throws -> LoginResult {
        if let token = String(data: identityToken, encoding: .utf8) {
            let endpoint = AuthEndpoint.login(idToken: token)
            let response: AuthResponseDTO = try await httpClient.request(endpoint)
            try tokenManager.set(response.accessToken)
            return LoginResult(isFirst: response.isFirst)
        } else {
            throw AppleLoginError.tokenPersistenceFailed
        }
    }
    
    public func logout() throws {
        try tokenManager.clear()
    }
}

