//
//  FoodGenre.swift
//  Domain
//

import Foundation

/// 음식 장르
public enum FoodGenre: String, CaseIterable, Equatable, Codable, Sendable {
    case korean = "한식"
    case chinese = "중식"
    case japanese = "일식"
    case western = "양식"
    case etc = "기타"

    public var displayName: String {
        rawValue
    }
}
