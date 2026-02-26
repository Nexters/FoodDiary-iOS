//
//  DiaryResponseDTO.swift
//  Data
//

import Domain
import Foundation

// MARK: - Response DTOs

/// GET /diaries 응답: { "diaries": [...] }
public struct DiariesResponseDTO: Decodable {
    public let diaries: [DiaryResponseDTO]
}

public struct DiaryResponseDTO: Decodable {
    public let id: Int
    public let diaryDate: String
    public let timeType: String
    public let analysisStatus: String
    public let restaurantName: String?
    public let restaurantUrl: String?
    public let roadAddress: String?
    public let category: String?
    public let coverPhotoUrl: String?
    public let tags: [String]?
    public let createdAt: String
    public let photos: [DiaryPhotoDTO]

    // 새 API 필드 (도메인에서 미사용)
    public let note: String?
    public let photoCount: Int?
    public let userId: String?
    public let coverPhotoId: Int?
    public let updatedAt: String?

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
        case restaurantUrl = "restaurant_url"
        case note
        case photoCount = "photo_count"
        case userId = "user_id"
        case coverPhotoId = "cover_photo_id"
        case updatedAt = "updated_at"
    }
}

public struct DiaryPhotoDTO: Decodable {
    public let photoId: Int
    public let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case imageUrl = "image_url"
    }
}

// MARK: - Suggestion DTOs

/// GET /diaries/{diary_id}/suggestions 응답
public struct DiarySuggestionsResponseDTO: Decodable {
    public let restaurants: [RestaurantCandidateDTO]
}

public struct RestaurantCandidateDTO: Decodable {
    public let name: String
    public let memo: String
    public let address: String?
    public let url: String?
    public let roadAddress: String?
    public let tags: [String]

    enum CodingKeys: String, CodingKey {
        case name, memo, address, url, tags
        case roadAddress = "road_address"
    }
}

/// POST /diaries/{diary_id}/photos 응답
public struct AddDiaryPhotosResponseDTO: Decodable {
    public let photoIds: [Int]

    enum CodingKeys: String, CodingKey {
        case photoIds = "photo_ids"
    }
}

// MARK: - DTO → Entity 변환

extension DiaryResponseDTO {
    func toFoodRecord() -> FoodRecord? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = .current

        guard let date = dateFormatter.date(from: diaryDate) else { return nil }

        let createdAtFormatter = DateFormatter()
        createdAtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        createdAtFormatter.timeZone = .current
        let createdDate = createdAtFormatter.date(from: createdAt) ?? date

        let photoInfos = photos.compactMap { dto -> PhotoInfo? in
            guard let url = URL(string: dto.imageUrl) else { return nil }
            return PhotoInfo(id: dto.photoId, imageURL: url)
        }
        let mealType = MealType.from(serverValue: timeType)
        let genre = category.flatMap { FoodGenre(rawValue: $0) } ?? .etc

        let status = AnalysisStatus(rawValue: analysisStatus) ?? .completed

        return FoodRecord(
            id: String(id),
            date: date,
            mealType: mealType,
            genre: genre,
            photos: photoInfos,
            restaurantName: restaurantName,
            restaurantUrl: restaurantUrl,
            address: roadAddress,
            hashtags: tags ?? [],
            createdAt: createdDate,
            analysisStatus: status
        )
    }
}
