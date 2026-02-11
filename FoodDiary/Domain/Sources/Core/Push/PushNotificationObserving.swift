//
//  PushNotificationObserving.swift
//  Domain
//

import Combine
import Foundation

public protocol PushNotificationObserving {
    var analysisResultPublisher: AnyPublisher<String, Never> { get }
}
