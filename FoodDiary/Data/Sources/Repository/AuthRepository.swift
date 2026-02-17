//
//  AuthRepository.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Domain
import Foundation

public struct AuthRepositoryImpl<Storage: AuthTokenStoring, Client: HTTPClienting>: AuthRepository {
    let httpClient: Client
    let tokenStorage: Storage

    public init(httpClient: Client, tokenStorage: Storage) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    public func login(_ request: LoginRequest) async throws -> LoginResult {
        let endpoint = AuthEndpoint.login(request: request)
        let response: AuthResponseDTO = try await httpClient.request(endpoint)
        try tokenStorage.set(response.accessToken)
        return LoginResult(isFirst: response.isFirst)
    }
    
    public func logout() throws {
        try tokenStorage.clear()
    }
}

