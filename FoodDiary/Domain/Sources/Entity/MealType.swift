//
//  MealType.swift
//  Domain
//

import Foundation

/// 식사 타입
public enum MealType: String, Sendable, CaseIterable, Equatable, Codable {
    case breakfast = "조식"
    case lunch = "중식"
    case dinner = "석식"
    case snack = "야식"

    public var displayName: String {
        rawValue
    }

    /// 시간 기반 자동 분류
    public static func classify(from hour: Int) -> MealType {
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<21: return .dinner
        default: return .snack
        }
    }

    /// 서버 API 값으로부터 변환 (breakfast, lunch, dinner, late_night)
    public static func from(serverValue: String) -> MealType {
        switch serverValue {
        case "breakfast": return .breakfast
        case "lunch": return .lunch
        case "dinner": return .dinner
        case "late_night", "snack": return .snack
        default: return .lunch
        }
    }

    /// 서버 API 값으로부터 변환 (breakfast, lunch, dinner, late_night)
    public static func from(serverValue: String) -> MealType {
        switch serverValue {
        case "breakfast": return .breakfast
        case "lunch": return .lunch
        case "dinner": return .dinner
        case "late_night": return .lateNight
        default: return .lunch
        }
    }
}
