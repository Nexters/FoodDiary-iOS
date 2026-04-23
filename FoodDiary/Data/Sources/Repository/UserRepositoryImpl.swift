//
//  UserRepositoryImpl.swift
//  Data
//
//  Created by 강대훈 on 2/24/26.
//

import Domain
import Foundation

public struct UserRepositoryImpl: UserRepository {
    private let httpClient: any HTTPClienting
    private let tokenStorage: any AuthTokenStoring

    public init(httpClient: any HTTPClienting, tokenStorage: any AuthTokenStoring) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    public func fetchProfile() async throws -> UserProfile {
        let endpoint = UserEndpoint.nickname
        let response: UserResponseDTO = try await httpClient.request(endpoint, accessToken: tokenStorage.get())
        return response.toUserProfile()
    }
}
