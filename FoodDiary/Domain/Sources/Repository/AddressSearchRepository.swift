//
//  AddressSearchRepository.swift
//  Domain
//

import Foundation

/// 주소 검색 결과
public struct AddressSearchResult: Equatable, Sendable {
    public let placeName: String
    public let roadAddress: String

    public init(placeName: String, roadAddress: String) {
        self.placeName = placeName
        self.roadAddress = roadAddress
    }
}

/// 주소 검색 Repository 프로토콜
public protocol AddressSearchRepository: Sendable {
    /// 키워드로 주소 검색
    func searchAddress(keyword: String, page: Int) async throws -> [AddressSearchResult]
    /// 식당 이름 기반 후보군 조회
    func fetchSuggestions(restaurantName: String) async throws -> [AddressSearchResult]
}
