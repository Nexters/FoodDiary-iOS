//
//  Analytics.swift
//  Presentation
//

import Domain
import DI

/// Presentation 계층에서 분석 이벤트를 기록하는 진입점
/// DI 컨테이너의 `AnalyticsService`를 지연 조회하며, 등록되지 않았다면 무시한다.
enum Analytics {
    private static let service: AnalyticsService? = {
        try? DIContainer.shared.resolve(AnalyticsService.self)
    }()

    static func track(_ event: AnalyticsEvent) {
        service?.track(event)
    }

    static func identify(userId: String) {
        service?.identify(userId: userId)
    }

    static func reset() {
        service?.reset()
    }
}
