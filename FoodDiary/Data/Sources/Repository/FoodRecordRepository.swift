//
//  FoodRecordRepository.swift
//  Data
//
//  Created by 강대훈 on 2/18/26.
//

import Domain
import Foundation

public struct FoodRecordRepositoryImpl<Client: HTTPClienting & Sendable, Storage: AuthTokenStoring & Sendable>: FoodRecordRepository {
    private let httpClient: Client
    private let tokenStorage: Storage

    public init(httpClient: Client, tokenStorage: Storage) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    public func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]] {
        let endpoint = DiaryEndpoint.fetchMonthlyTest(startDate: dateRange.lowerBound.apiDateString, endDate: dateRange.upperBound.apiDateString)
        let response: DiariesResponseDTO = try await httpClient.request(endpoint, accessToken: tokenStorage.get())
        return response.toDomain()
    }

    public func fetchRecords(for date: Date) async throws -> [FoodRecord] {
        // TODO: 구현 예정
        return []
    }

    public func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> String {
        // TODO: 구현 예정
        return ""
    }
}
