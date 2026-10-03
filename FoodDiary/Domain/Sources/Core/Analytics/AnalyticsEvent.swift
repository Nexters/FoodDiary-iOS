//
//  AnalyticsEvent.swift
//  Domain
//

import Foundation

/// 앱에서 수집하는 분석 이벤트 목록
/// 이벤트 이름과 속성은 이곳에서만 정의해 문자열이 흩어지지 않도록 한다.
public enum AnalyticsEvent: Sendable, Equatable {
    // MARK: 유입 / 체류
    /// 앱 실행
    case appOpen
    /// 화면 진입
    case screenView(screen: String)
    /// 화면 체류 시간 (화면을 벗어나거나 앱이 비활성화될 때)
    case screenDuration(screen: String, seconds: Double)

    // MARK: 버튼
    /// 버튼 탭
    case buttonTap(button: String, screen: String)

    // MARK: 이탈 분석용 퍼널 단계
    /// 온보딩 종료 (skipped: 건너뛰기 여부)
    case onboardingFinish(skipped: Bool)
    /// 로그인 성공
    case loginSuccess
    /// 로그인 실패
    case loginFailure
    /// 식단 기록 저장 완료 (isNew: 신규 작성 여부)
    case recordSaved(isNew: Bool)

    /// Mixpanel 등에 전달되는 이벤트 이름
    public var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .screenView: return "screen_view"
        case .screenDuration: return "screen_duration"
        case .buttonTap: return "button_tap"
        case .onboardingFinish: return "onboarding_finish"
        case .loginSuccess: return "login_success"
        case .loginFailure: return "login_failure"
        case .recordSaved: return "record_saved"
        }
    }

    /// 이벤트 속성 (개인정보는 포함하지 않는다)
    public var properties: [String: AnalyticsValue] {
        switch self {
        case .appOpen, .loginSuccess, .loginFailure:
            return [:]
        case .screenView(let screen):
            return ["screen_name": .string(screen)]
        case .screenDuration(let screen, let seconds):
            return ["screen_name": .string(screen), "duration_sec": .double(seconds)]
        case .buttonTap(let button, let screen):
            return ["button_name": .string(button), "screen_name": .string(screen)]
        case .onboardingFinish(let skipped):
            return ["skipped": .bool(skipped)]
        case .recordSaved(let isNew):
            return ["is_new": .bool(isNew)]
        }
    }
}
