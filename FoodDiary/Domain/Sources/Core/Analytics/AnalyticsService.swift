//
//  AnalyticsService.swift
//  Domain
//

import Foundation

/// 사용자 행동 분석 이벤트를 수집하는 프로토콜
public protocol AnalyticsService: Sendable {
    /// 이벤트를 기록
    func track(_ event: AnalyticsEvent)

    /// 로그인한 사용자를 식별
    /// - Parameter userId: 서비스 내부 사용자 식별자 (이메일 등 개인정보 금지)
    func identify(userId: String)

    /// 로그아웃 시 사용자 식별 정보를 초기화
    func reset()
}
