//
//  InsightRepositoryImpl.swift
//  Data
//

import Domain
import Foundation

public struct InsightRepositoryImpl<Client: HTTPClienting, Storage: AuthTokenStoring>: InsightRepository {
    private let httpClient: Client
    private let tokenStorage: Storage

    public init(httpClient: Client, tokenStorage: Storage) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    public func fetchInsight() async throws -> Insight {
        do {
            let response: InsightResponseDTO = try await httpClient.request(
                InsightEndpoint.fetch,
                accessToken: tokenStorage.get()
            )
            return response.toInsight()
        } catch NetworkError.httpError(statusCode: 400, _) {
            throw InsightError.insufficientData
        }
    }
}
