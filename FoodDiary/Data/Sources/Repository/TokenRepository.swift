//
//  TokenRepository.swift
//  Data
//
//  Created by 강대훈 on 2/10/26.
//

import Domain
import Foundation

public struct TokenRepositoryImpl<Client: HTTPClienting, Storage: AuthTokenStoring>: TokenRepository {
    let httpClient: Client
    let storage: Storage

    public init(httpClient: Client, storage: Storage) {
        self.httpClient = httpClient
        self.storage = storage
    }

    public func verifyToken() async -> Bool {
        guard let accessToken = storage.get() else {
            return false
        }
        
        guard let _: ValidateResponseDTO = try? await httpClient.request(AuthEndpoint.verify, accessToken: accessToken) else {
            return false
        }
        
        return true
    }
}
