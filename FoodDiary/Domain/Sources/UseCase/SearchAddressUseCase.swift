//
//  SearchAddressUseCase.swift
//  Domain
//

import Foundation

public struct SearchAddressUseCase<Repository: AddressSearchRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(keyword: String, page: Int = 1) async throws -> [AddressSearchResult] {
        try await repository.searchAddress(keyword: keyword, page: page)
    }

    public func fetchSuggestions(restaurantName: String) async throws -> [AddressSearchResult] {
        try await repository.fetchSuggestions(restaurantName: restaurantName)
    }
}
