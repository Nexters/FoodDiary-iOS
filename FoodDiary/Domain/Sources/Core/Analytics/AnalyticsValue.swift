//
//  AnalyticsValue.swift
//  Domain
//

import Foundation

/// 이벤트 속성 값 (문자열·숫자·불리언만 허용)
public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

extension AnalyticsValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
