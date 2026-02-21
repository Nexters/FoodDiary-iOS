//
//  FoodRecord.swift
//  Domain
//

import Foundation

/// 사진 정보 (ID + URL)
public struct PhotoInfo: Equatable, Sendable {
    public let id: Int
    public let imageURL: URL

    public init(id: Int, imageURL: URL) {
        self.id = id
        self.imageURL = imageURL
    }
}

/// 서버에서 받아온 음식 기록 정보
public struct FoodRecord: Identifiable, Equatable, Sendable {
    public let id: String
    public let date: Date
    public let mealType: MealType
    public let genre: FoodGenre
    public let photos: [PhotoInfo]
    public let restaurantName: String?
    public let address: String?
    public let hashtags: [String]
    public let createdAt: Date

    /// 하위 호환용 computed property
    public var imageURLs: [URL] {
        photos.map(\.imageURL)
    }

    public init(
        id: String,
        date: Date,
        mealType: MealType,
        genre: FoodGenre,
        photos: [PhotoInfo],
        restaurantName: String? = nil,
        address: String? = nil,
        hashtags: [String] = [],
        createdAt: Date
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.genre = genre
        self.photos = photos
        self.restaurantName = restaurantName
        self.address = address
        self.hashtags = hashtags
        self.createdAt = createdAt
    }

    /// 포맷된 시간 (예: "오후 1시 12분")
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h시 m분"
        return formatter.string(from: createdAt)
    }

    /// 짧은 포맷 시간 (예: "07:00")
    public var formattedShortTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }

    /// 주소에서 구 정보 추출 (예: "마포구")
    public var district: String? {
        guard let address else { return nil }
        let pattern = "([가-힣]+구)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: address,
                  range: NSRange(address.startIndex..., in: address)
              ),
              let range = Range(match.range(at: 1), in: address)
        else {
            return nil
        }
        return String(address[range])
    }
}
