//
//  DeviceRepositoryImpl.swift
//  Data
//
//  Created by 강대훈 on 2/20/26.
//

import Domain
import Foundation

public struct DeviceRepositoryImpl<Client: HTTPClienting, Storage: AuthTokenStoring>: DeviceRepository {
    private let httpClient: Client
    private let tokenStorage: Storage

    public init(httpClient: Client, tokenStorage: Storage) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    public func updateNotificationSetting(_ request: UpdateDeviceNotificationRequest) async throws {
        let endpoint = DeviceEndpoint.me(request: request)
        let _: EmptyResponse = try await httpClient.request(endpoint, accessToken: tokenStorage.get())
    }
}
