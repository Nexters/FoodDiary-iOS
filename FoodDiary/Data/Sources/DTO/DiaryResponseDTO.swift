//
//  DiaryResponseDTO.swift
//  Data
//

import Domain
import Foundation

// MARK: - Response DTOs

/// GET /diaries 응답: { "2026-02-16": { "diaries": [...] } }
public typealias DiariesResponseDTO = [String: DiaryDateResponseDTO]

public struct DiaryDateResponseDTO: Decodable {
    public let diaries: [DiaryResponseDTO]
}

public struct DiaryResponseDTO: Decodable {
    public let id: Int
    public let diaryDate: String
    public let timeType: String
    public let analysisStatus: String
    public let restaurantName: String?
    public let roadAddress: String?
    public let category: String?
    public let coverPhotoUrl: String?
    public let tags: [String]?
    public let createdAt: String
    public let photos: [DiaryPhotoDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case diaryDate = "diary_date"
        case timeType = "time_type"
        case analysisStatus = "analysis_status"
        case restaurantName = "restaurant_name"
        case roadAddress = "road_address"
        case category
        case coverPhotoUrl = "cover_photo_url"
        case tags
        case createdAt = "created_at"
        case photos
    }
}

public struct DiaryPhotoDTO: Decodable {
    public let photoId: Int
    public let imageUrl: String
    public let analysisStatus: String

    enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case imageUrl = "image_url"
        case analysisStatus = "analysis_status"
    }
}

// MARK: - DTO → Entity 변환

extension DiaryResponseDTO {
    func toFoodRecord() -> FoodRecord? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = .current

        guard let date = dateFormatter.date(from: diaryDate) else { return nil }

        let createdAtFormatter = DateFormatter()
        createdAtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        createdAtFormatter.timeZone = .current
        let createdDate = createdAtFormatter.date(from: createdAt) ?? date

        let imageURLs = photos.compactMap { URL(string: $0.imageUrl) }
        let mealType = MealType.from(serverValue: timeType)
        let genre = category.flatMap { FoodGenre(rawValue: $0) } ?? .etc

        return FoodRecord(
            id: String(id),
            date: date,
            mealType: mealType,
            genre: genre,
            imageURLs: imageURLs,
            restaurantName: restaurantName,
            address: roadAddress,
            hashtags: tags ?? [],
            createdAt: createdDate
        )
    }
}
