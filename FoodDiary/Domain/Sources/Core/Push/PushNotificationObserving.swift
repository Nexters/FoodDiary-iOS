//
//  PushNotificationObserving.swift
//  Domain
//

import Combine
import Foundation

public protocol PushNotificationObserving {
    var analysisResultPublisher: AnyPublisher<String, Never> { get }
}

public enum PushNotificationKey {
    public static let analysisResult = Notification.Name("PushNotification.analysisResult")
    public static let uploadIdKey = "uploadId"
}
