//
//  DeviceRepositoryImpl.swift
//  Data
//
//  Created by 강대훈 on 2/20/26.
//

import Domain
import Foundation

public struct DeviceRepositoryImpl: DeviceRepository {
    private let httpClient: any HTTPClienting
    private let tokenStorage: any AuthTokenStoring

    public init(httpClient: any HTTPClienting, tokenStorage: any AuthTokenStoring) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    public func updateNotificationSetting(_ request: UpdateDeviceNotificationRequest) async throws {
        let endpoint = DeviceEndpoint.me(request: request)
        let _: EmptyResponse = try await httpClient.request(endpoint, accessToken: tokenStorage.get())
    }
}
