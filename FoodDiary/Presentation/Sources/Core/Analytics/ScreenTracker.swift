//
//  ScreenTracker.swift
//  Presentation
//

import UIKit
import Domain

/// 화면 분석 이름을 제공하는 화면(UIViewController)이 채택하는 프로토콜
/// 채택한 화면만 `screen_view`, `screen_duration` 이벤트가 자동으로 기록된다.
public protocol AnalyticsScreen: UIViewController {
    var analyticsScreenName: String { get }
}

/// 화면 진입/이탈을 감지해 화면 조회와 체류 시간을 기록
@MainActor
final class ScreenTracker {
    static let shared = ScreenTracker()

    private struct Session {
        let name: String
        var startedAt: Date?
    }

    /// 현재 노출 중인 화면 (push 전환 시 새 화면이 먼저 나타나므로 식별자로 구분)
    private var sessions: [ObjectIdentifier: Session] = [:]
    private var isObservingApp = false

    func screenDidAppear(_ viewController: UIViewController & AnalyticsScreen) {
        observeAppStateIfNeeded()
        let id = ObjectIdentifier(viewController)
        let name = viewController.analyticsScreenName
        sessions[id] = Session(name: name, startedAt: Date())
        Analytics.track(.screenView(screen: name))
    }

    func screenDidDisappear(_ viewController: UIViewController & AnalyticsScreen) {
        let id = ObjectIdentifier(viewController)
        guard let session = sessions.removeValue(forKey: id) else { return }
        report(session)
    }

    // MARK: - 앱 상태 (백그라운드 시간은 체류 시간에서 제외)

    private func observeAppStateIfNeeded() {
        guard !isObservingApp else { return }
        isObservingApp = true
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.pauseAll() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.resumeAll() }
        }
    }

    private func pauseAll() {
        for (id, session) in sessions {
            report(session)
            sessions[id]?.startedAt = nil
        }
    }

    private func resumeAll() {
        let now = Date()
        for id in sessions.keys where sessions[id]?.startedAt == nil {
            sessions[id]?.startedAt = now
        }
    }

    private func report(_ session: Session) {
        guard let startedAt = session.startedAt else { return }
        let seconds = Date().timeIntervalSince(startedAt)
        guard seconds >= 0.5 else { return }
        Analytics.track(.screenDuration(screen: session.name, seconds: (seconds * 10).rounded() / 10))
    }
}

// MARK: - 자동 추적 활성화

extension UIViewController {
    /// `AnalyticsScreen`을 채택한 화면의 viewDidAppear/viewDidDisappear를 가로채 추적한다.
    /// 앱 시작 시 한 번만 호출한다.
    @MainActor
    public static func enableScreenTracking() {
        guard !isScreenTrackingEnabled else { return }
        isScreenTrackingEnabled = true
        swizzle(#selector(viewDidAppear(_:)), #selector(analytics_viewDidAppear(_:)))
        swizzle(#selector(viewDidDisappear(_:)), #selector(analytics_viewDidDisappear(_:)))
    }

    @MainActor private static var isScreenTrackingEnabled = false

    private static func swizzle(_ original: Selector, _ replacement: Selector) {
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, original),
              let replacementMethod = class_getInstanceMethod(UIViewController.self, replacement)
        else { return }
        method_exchangeImplementations(originalMethod, replacementMethod)
    }

    @objc private func analytics_viewDidAppear(_ animated: Bool) {
        analytics_viewDidAppear(animated)  // 교체된 원본 구현 호출
        if let screen = self as? (UIViewController & AnalyticsScreen) {
            MainActor.assumeIsolated { ScreenTracker.shared.screenDidAppear(screen) }
        }
    }

    @objc private func analytics_viewDidDisappear(_ animated: Bool) {
        analytics_viewDidDisappear(animated)
        if let screen = self as? (UIViewController & AnalyticsScreen) {
            MainActor.assumeIsolated { ScreenTracker.shared.screenDidDisappear(screen) }
        }
    }
}
