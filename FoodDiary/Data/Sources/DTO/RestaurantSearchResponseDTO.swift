//
//  RestaurantSearchResponseDTO.swift
//  Data
//

import Foundation

/// GET /restaurant/search 응답
public struct RestaurantSearchResponseDTO: Decodable {
    public let restaurants: [RestaurantItemDTO]
    public let totalCount: Int
    public let page: Int
    public let size: Int
    public let isEnd: Bool

    enum CodingKeys: String, CodingKey {
        case restaurants
        case totalCount = "total_count"
        case page, size
        case isEnd = "is_end"
    }
}

public struct RestaurantItemDTO: Decodable {
    public let name: String
    public let roadAddress: String
    public let url: String

    enum CodingKeys: String, CodingKey {
        case name
        case roadAddress = "road_address"
        case url
    }
}
