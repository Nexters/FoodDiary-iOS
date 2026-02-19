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
    
    public func fetchPhotoURLs(in dateRange: ClosedRange<Date>) async throws -> [Date: [URL]] {
        let endpoint = DiaryEndpoint.fetchMonthlyTest(
            startDate: dateRange.lowerBound.apiDateString,
            endDate: dateRange.upperBound.apiDateString,
            testMode: true
        )
        let response: CalendarPhotoResponseDTO = try await httpClient.request(
            endpoint,
            accessToken: tokenStorage.get()
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return response.reduce(into: [Date: [URL]]()) { result, entry in
            guard let date = formatter.date(from: entry.key) else { return }
            result[date] = entry.value.photos.compactMap { URL(string: $0) }
        }
    }

    public func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]] {
        return [:]
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
