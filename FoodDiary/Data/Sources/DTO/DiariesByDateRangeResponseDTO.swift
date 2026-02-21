//
//  DiariesByDateResponseDTO.swift
//  Data
//
//  Created by 강대훈 on 2/21/26.
//

import Foundation

public struct DiariesByDateRangeResponseDTO: Decodable {
    let diaries: [DiaryDTO]
}

/// 사진 목록을 포함한 다이어리 응답
struct DiaryDTO: Decodable {
    let diaryDate: String
    let timeType: TimeTypeDTO
    let restaurantName: String?
    let restaurantURL: String?
    let roadAddress: String?
    let category: String?
    let note: String?
    let tags: [String]
    let photoCount: Int
    let id: Int
    let userID: String
    let coverPhotoID: Int?
    let coverPhotoURL: String?
    let createdAt: String
    let updatedAt: String
    let analysisStatus: String
    let photos: [DiaryPhotoDTO]

    enum CodingKeys: String, CodingKey {
        case diaryDate       = "diary_date"
        case timeType        = "time_type"
        case restaurantName  = "restaurant_name"
        case restaurantURL   = "restaurant_url"
        case roadAddress     = "road_address"
        case category
        case note
        case tags
        case photoCount      = "photo_count"
        case id
        case userID          = "user_id"
        case coverPhotoID    = "cover_photo_id"
        case coverPhotoURL   = "cover_photo_url"
        case createdAt       = "created_at"
        case updatedAt       = "updated_at"
        case analysisStatus  = "analysis_status"
        case photos
    }
}


public enum TimeTypeDTO: String, Decodable {
    case breakfast
    case lunch
    case dinner
    case snack
}

/// 다이어리 내 사진 정보
struct DiaryPhotoDTO: Decodable {
    let photoID: Int
    let imageURL: String
    let analysisStatus: String

    enum CodingKeys: String, CodingKey {
        case photoID        = "photo_id"
        case imageURL       = "image_url"
        case analysisStatus = "analysis_status"
    }
}
