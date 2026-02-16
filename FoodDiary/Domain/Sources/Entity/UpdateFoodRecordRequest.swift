//
//  UpdateFoodRecordRequest.swift
//  Domain
//

import Foundation
import UIKit

/// 음식 기록 수정 요청 데이터
public struct UpdateFoodRecordRequest: Sendable {
    public let id: String
    public let genre: FoodGenre
    public let existingImageURLs: [URL]
    public let newImages: [UIImage]
    public let address: String?
    public let detailAddress: String?
    public let hashtags: [String]

    public init(
        id: String,
        genre: FoodGenre,
        existingImageURLs: [URL],
        newImages: [UIImage],
        address: String?,
        detailAddress: String?,
        hashtags: [String]
    ) {
        self.id = id
        self.genre = genre
        self.existingImageURLs = existingImageURLs
        self.newImages = newImages
        self.address = address
        self.detailAddress = detailAddress
        self.hashtags = hashtags
    }
}
