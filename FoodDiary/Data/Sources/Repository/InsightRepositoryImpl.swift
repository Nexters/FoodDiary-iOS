//
//  InsightRepositoryImpl.swift
//  Data
//

import Domain
import Foundation

public struct InsightRepositoryImpl: InsightRepository {
    private let httpClient: any HTTPClienting
    private let tokenStorage: any AuthTokenStoring

    public init(httpClient: any HTTPClienting, tokenStorage: any AuthTokenStoring) {
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
