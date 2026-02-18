//
//  BatchUploadResponseDTO.swift
//  Data
//
//  Created by 강대훈 on 2/17/26.
//

import Foundation

public struct BatchUploadResponseDTO: Decodable {
    public let results: [PhotoResultDTO]
}

public struct PhotoResultDTO: Decodable {
    public let photoId: Int
    public let diaryId: Int
    public let timeType: String
    public let imageURL: String
    public let analysisStatus: String

    enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case diaryId = "diary_id"
        case timeType = "time_type"
        case imageURL = "image_url"
        case analysisStatus = "analysis_status"
    }
}
