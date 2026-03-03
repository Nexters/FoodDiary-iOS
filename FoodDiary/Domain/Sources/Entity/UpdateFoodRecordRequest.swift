//
//  UpdateFoodRecordRequest.swift
//  Domain
//

import Foundation

/// 음식 기록 수정 요청 데이터
public struct UpdateFoodRecordRequest: Sendable {
    public let id: String
    public let genre: FoodGenre
    public let existingPhotoIds: [Int]
    public let newAssets: [any ImageAssetable]
    public let address: String?
    public let restaurantName: String?
    public let restaurantURL: String?
    public let hashtags: [String]
    public let note: String?
    public let coverPhotoId: Int?

    public init(
        id: String,
        genre: FoodGenre,
        existingPhotoIds: [Int],
        newAssets: [any ImageAssetable],
        address: String?,
        restaurantName: String?,
        restaurantURL: String?,
        hashtags: [String],
        note: String? = nil,
        coverPhotoId: Int? = nil
    ) {
        self.id = id
        self.genre = genre
        self.existingPhotoIds = existingPhotoIds
        self.newAssets = newAssets
        self.address = address
        self.restaurantName = restaurantName
        self.restaurantURL = restaurantURL
        self.hashtags = hashtags
        self.note = note
        self.coverPhotoId = coverPhotoId
    }
}
