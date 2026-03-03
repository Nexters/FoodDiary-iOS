//
//  BatchUploadResponseDTO.swift
//  Data
//
//  Created by 강대훈 on 2/17/26.
//

import Foundation

public struct BatchUploadResponseDTO: Decodable {
    public let diaryDate: String
    public let diaries: [DiaryResultDTO]

    enum CodingKeys: String, CodingKey {
        case diaryDate = "diary_date"
        case diaries
    }
}

public struct DiaryResultDTO: Decodable {
    public let diaryId: Int
    public let diaryStatus: String
    public let timeType: String

    enum CodingKeys: String, CodingKey {
        case diaryId = "diary_id"
        case diaryStatus = "diary_status"
        case timeType = "time_type"
    }
}
