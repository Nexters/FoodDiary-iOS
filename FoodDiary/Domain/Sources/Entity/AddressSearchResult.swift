//
//  AddressSearchResult.swift
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
