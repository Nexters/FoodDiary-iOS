//
//  AddressSearchRepository.swift
//  Domain
//

import Foundation

/// 주소 검색 Repository 프로토콜
public protocol AddressSearchRepository: Sendable {
    /// 키워드로 주소 검색
    func searchAddress(keyword: String, page: Int) async throws -> [AddressSearchResult]
    /// diary_id 기반 서버 suggestion API 호출
    func fetchSuggestions(diaryId: Int) async throws -> [AddressSearchResult]
}
