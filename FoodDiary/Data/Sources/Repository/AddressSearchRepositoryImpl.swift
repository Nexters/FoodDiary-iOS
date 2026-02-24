//
//  AddressSearchRepositoryImpl.swift
//  Data
//

import Domain
import Foundation

/// AddressSearchRepository 실제 서버 API 구현체
public struct AddressSearchRepositoryImpl: AddressSearchRepository {
    private let httpClient: any HTTPClienting
    private let tokenStorage: any AuthTokenStoring

    public init(httpClient: any HTTPClienting, tokenStorage: any AuthTokenStoring) {
        self.httpClient = httpClient
        self.tokenStorage = tokenStorage
    }

    public func fetchSuggestions(diaryId: Int) async throws -> [AddressSearchResult] {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let endpoint = DiaryEndpoint.suggestions(diaryId: diaryId)
        let response: DiarySuggestionsResponseDTO = try await httpClient.request(
            endpoint,
            accessToken: accessToken
        )

        return response.restaurants.map { candidate in
            AddressSearchResult(
                placeName: candidate.name,
                roadAddress: candidate.roadAddress ?? candidate.address ?? "",
                url: candidate.url
            )
        }
    }

    public func searchAddress(keyword: String, page: Int) async throws -> [AddressSearchResult] {
        guard let accessToken = tokenStorage.get() else {
            throw FoodRecordError.noAccessToken
        }

        let endpoint = RestaurantEndpoint.search(
            diaryId: nil,
            keyword: keyword,
            page: page,
            size: 15
        )
        let response: RestaurantSearchResponseDTO = try await httpClient.request(
            endpoint,
            accessToken: accessToken
        )

        return response.restaurants.map { item in
            AddressSearchResult(
                placeName: item.name,
                roadAddress: item.roadAddress,
                url: item.url
            )
        }
    }
}
