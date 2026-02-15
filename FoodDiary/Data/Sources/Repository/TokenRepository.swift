//
//  TokenRepository.swift
//  Data
//
//  Created by 강대훈 on 2/10/26.
//

import Domain
import Foundation

public struct TokenRepositoryImpl<Client: HTTPClienting, Manager: TokenManaging>: TokenRepository {
    let httpClient: Client
    let manager: Manager

    public init(httpClient: Client, manager: Manager) {
        self.httpClient = httpClient
        self.manager = manager
    }

    public func verifyToken() async -> Bool {
        guard let accessToken = manager.get() else {
            return false
        }
        
        guard let _: ValidateResponseDTO = try? await httpClient.request(AuthEndpoint.verify, accessToken: accessToken) else {
            return false
        }
        
        return true
    }
}
