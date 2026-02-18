//
//  DiariesResponseDTO.swift
//  Data
//
//  Created by 강대훈 on 2/18/26.
//

import Domain
import Foundation

public typealias DiariesResponseDTO = [String: DailyDiaryDTO]

public struct DailyDiaryDTO: Decodable {
    public let diaries: [DiaryDTO]

    enum CodingKeys: String, CodingKey {
        case diaries
    }
}

public struct DiaryDTO: Decodable {
    public let id: Int
    public let userId: String
    public let diaryDate: String
    public let timeType: TimeTypeDTO
    public let analysisStatus: AnalysisStatusDTO

    public let restaurantName: String?
    public let restaurantUrl: String?
    public let roadAddress: String?
    public let category: String?

    public let coverPhotoId: Int
    public let coverPhotoUrl: String

    public let note: String?
    public let tags: [String]
    public let photoCount: Int

    public let createdAt: String
    public let updatedAt: String

    public let photos: [PhotoDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case diaryDate = "diary_date"
        case timeType = "time_type"
        case analysisStatus = "analysis_status"

        case restaurantName = "restaurant_name"
        case restaurantUrl = "restaurant_url"
        case roadAddress = "road_address"
        case category

        case coverPhotoId = "cover_photo_id"
        case coverPhotoUrl = "cover_photo_url"

        case note
        case tags
        case photoCount = "photo_count"

        case createdAt = "created_at"
        case updatedAt = "updated_at"

        case photos
    }
}

// MARK: - Photo

public struct PhotoDTO: Decodable {
    public let photoId: Int
    public let imageUrl: String
    public let analysisStatus: AnalysisStatusDTO

    enum CodingKeys: String, CodingKey {
        case photoId = "photo_id"
        case imageUrl = "image_url"
        case analysisStatus = "analysis_status"
    }
}

// MARK: - Enums

public enum TimeTypeDTO: String, Decodable {
    case breakfast
    case lunch
    case dinner
}

public enum AnalysisStatusDTO: String, Decodable {
    case done
    case processing
}

extension DiariesResponseDTO {
    public func toDomain() -> [Date: [FoodRecord]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        var result: [Date: [FoodRecord]] = [:]
        for (dateString, dailyDTO) in self {
            guard let date = dateFormatter.date(from: dateString) else { continue }
            result[date] = dailyDTO.diaries.map { $0.toDomain(dateFormatter: dateFormatter) }
        }
        return result
    }
}

extension DiaryDTO {
    public func toDomain(dateFormatter: DateFormatter) -> FoodRecord {
        let imageURLs = photos.compactMap { URL(string: $0.imageUrl) }
        let date = dateFormatter.date(from: diaryDate) ?? Date()
        let createdAt = ISO8601DateFormatter().date(from: self.createdAt) ?? Date()

        return FoodRecord(
            id: String(id),
            date: date,
            mealType: timeType.toDomain(),
            genre: FoodGenre(rawValue: category ?? "") ?? .etc,
            imageURLs: imageURLs,
            restaurantName: restaurantName,
            address: roadAddress,
            hashtags: tags,
            createdAt: createdAt
        )
    }
}

extension TimeTypeDTO {
    public func toDomain() -> MealType {
        switch self {
        case .breakfast: return .breakfast
        case .lunch:     return .lunch
        case .dinner:    return .dinner
        }
    }
}
