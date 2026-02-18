//
//  AddressSearchRepository.swift
//  Domain
//

import Foundation

/// 주소 검색 Repository 프로토콜
public protocol AddressSearchRepository: Sendable {
    /// 키워드로 주소 검색
    func searchAddress(keyword: String, page: Int) async throws -> [AddressSearchResult]
    /// 식당 이름 기반 후보군 조회
    func fetchSuggestions(restaurantName: String) async throws -> [AddressSearchResult]
}
