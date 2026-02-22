//
//  DiaryUpdateRequestDTO.swift
//  Data
//

import Foundation

public struct DiaryUpdateRequestDTO: Encodable {
    public let category: String?
    public let restaurantName: String?
    public let restaurantUrl: String?
    public let roadAddress: String?
    public let tags: [String]?
    public let note: String?
    public let coverPhotoId: Int?
    public let photoIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case category
        case restaurantName = "restaurant_name"
        case restaurantUrl = "restaurant_url"
        case roadAddress = "road_address"
        case tags
        case note
        case coverPhotoId = "cover_photo_id"
        case photoIds = "photo_ids"
    }
}
