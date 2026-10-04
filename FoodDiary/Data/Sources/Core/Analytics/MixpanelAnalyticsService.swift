//
//  MixpanelAnalyticsService.swift
//  Data
//

import Foundation
import Mixpanel
import Domain

public final class MixpanelAnalyticsService: AnalyticsService, @unchecked Sendable {
    private let instance: MixpanelInstance

    /// - Parameter token: Mixpanel Project Token
    public init(token: String) {
        instance = Mixpanel.initialize(token: token, trackAutomaticEvents: false)
    }

    public func track(_ event: AnalyticsEvent) {
        instance.track(event: event.name, properties: event.properties.mapValues(\.mixpanelValue))
    }

    public func identify(userId: String) {
        instance.identify(distinctId: userId)
    }

    public func reset() {
        instance.reset()
    }
}

private extension AnalyticsValue {
    var mixpanelValue: MixpanelType {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        }
    }
}

/// 토큰이 없을 때(미설정 빌드, 테스트 등) 사용하는 아무 동작도 하지 않는 구현체
public struct NoopAnalyticsService: AnalyticsService {
    public init() {}

    public func track(_ event: AnalyticsEvent) {}
    public func identify(userId: String) {}
    public func reset() {}
}
