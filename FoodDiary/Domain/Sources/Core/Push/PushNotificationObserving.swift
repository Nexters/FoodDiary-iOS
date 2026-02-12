//
//  PushNotificationObserving.swift
//  Domain
//

import Combine
import Foundation

/// 분석 완료 푸시 알림 데이터
public struct AnalysisResultNotification: Sendable {
    public let uploadId: String
    public let date: Date

    public init(uploadId: String, date: Date) {
        self.uploadId = uploadId
        self.date = date
    }
}

/// 푸시 알림을 그대로 전달하는 Observer
public protocol PushNotificationObserving: Sendable {
    var analysisResultPublisher: AnyPublisher<AnalysisResultNotification, Never> { get }
}
