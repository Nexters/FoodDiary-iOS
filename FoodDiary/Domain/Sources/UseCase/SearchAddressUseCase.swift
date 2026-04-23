//
//  SearchAddressUseCase.swift
//  Domain
//

import Foundation

public struct SearchAddressUseCase: Sendable {
    private let repository: any AddressSearchRepository

    public init(repository: any AddressSearchRepository) {
        self.repository = repository
    }

    public func searchAddress(keyword: String, page: Int = 1) async throws -> [AddressSearchResult] {
        try await repository.searchAddress(keyword: keyword, page: page)
    }

    public func fetchSuggestions(diaryId: Int) async throws -> [AddressSearchResult] {
        try await repository.fetchSuggestions(diaryId: diaryId)
    }
}
