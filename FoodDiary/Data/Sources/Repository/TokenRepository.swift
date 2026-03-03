//
//  TokenRepository.swift
//  Data
//
//  Created by 강대훈 on 2/10/26.
//

import Domain
import Foundation

public struct TokenRepositoryImpl<
    Client: HTTPClienting,
    Storage: AuthTokenStoring,
    LaunchStorage: InitialLaunchStoring
>: TokenRepository {
    let httpClient: Client
    let storage: Storage
    let launchStorage: LaunchStorage

    public init(httpClient: Client, storage: Storage, launchStorage: LaunchStorage) {
        self.httpClient = httpClient
        self.storage = storage
        self.launchStorage = launchStorage
    }

    public func verifyToken() async -> Bool {
        guard launchStorage.get() else { return false }
        
        guard let accessToken = storage.get() else {
            return false
        }
        print("[TokenRepository] Access Token found: \(accessToken)")
        guard let _: ValidateResponseDTO = try? await httpClient.request(AuthEndpoint.verify, accessToken: accessToken) else {
            return false
        }

        return true
    }
}
