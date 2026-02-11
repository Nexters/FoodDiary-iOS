//
//  MockPushNotificationObserver.swift
//  Data
//

import Combine
import Domain
import Foundation

public final class MockPushNotificationObserver: PushNotificationObserving {
    private let subject = PassthroughSubject<String, Never>()

    public var analysisResultPublisher: AnyPublisher<String, Never> {
        subject.eraseToAnyPublisher()
    }

    public init() {
        scheduleSimulatedPush()
    }

    private func scheduleSimulatedPush() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.subject.send("mock-upload-id-\(UUID().uuidString)")
        }
    }
}
