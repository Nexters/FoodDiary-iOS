//
//  PushNotificationObserver.swift
//  Data
//

import Combine
import Domain
import Foundation

public final class PushNotificationObserver: PushNotificationObserving {
    public var analysisResultPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(for: PushNotificationKey.analysisResult)
            .compactMap { $0.userInfo?[PushNotificationKey.uploadIdKey] as? String }
            .eraseToAnyPublisher()
    }

    public init() {}
}
