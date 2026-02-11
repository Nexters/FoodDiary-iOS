//
//  PushNotificationObserver.swift
//  Data
//

import Combine
import Domain
import Foundation

public final class PushNotificationObserver: PushNotificationObserving {
    public var analysisResultPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(for: AppNotification.Push.analysisResult)
            .compactMap { $0.userInfo?[AppNotification.Push.Key.uploadId] as? String }
            .eraseToAnyPublisher()
    }

    public init() {}
}
