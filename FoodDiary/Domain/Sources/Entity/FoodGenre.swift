//
//  FoodGenre.swift
//  Domain
//

import Foundation

/// 음식 장르
public enum FoodGenre: String, CaseIterable, Equatable, Codable, Sendable {
    case korean = "korean"
    case chinese = "chinese"
    case japanese = "japanese"
    case western = "western"
    case homeCooked = "home_cooked"
    case etc = "etc"

    public var displayName: String {
        switch self {
        case .korean: return "한식"
        case .chinese: return "중식"
        case .japanese: return "일식"
        case .western: return "양식"
        case .homeCooked: return "집밥"
        case .etc: return "기타"
        }
    }
}
