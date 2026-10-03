//
//  LoggingAnalyticsService.swift
//  Data
//

import Foundation
import Domain

/// 다른 AnalyticsService를 감싸 기록되는 이벤트를 콘솔에 출력하는 구현체
public struct LoggingAnalyticsService: AnalyticsService {
    private let base: AnalyticsService

    public init(wrapping base: AnalyticsService) {
        self.base = base
    }

    public func track(_ event: AnalyticsEvent) {
        let properties = event.properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.description)" }
            .joined(separator: ", ")
        print("[Analytics] \(event.name)" + (properties.isEmpty ? "" : " { \(properties) }"))
        base.track(event)
    }

    public func identify(userId: String) {
        print("[Analytics] identify - \(userId)")
        base.identify(userId: userId)
    }

    public func reset() {
        print("[Analytics] reset")
        base.reset()
    }
}

private extension AnalyticsValue {
    var description: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return String(value)
        }
    }
}
