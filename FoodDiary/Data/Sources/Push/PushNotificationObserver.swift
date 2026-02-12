//
//  PushNotificationObserver.swift
//  Data
//

import Combine
import Domain
import Foundation

public final class PushNotificationObserver: PushNotificationObserving {
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public var analysisResultPublisher: AnyPublisher<AnalysisResultNotification, Never> {
        NotificationCenter.default.publisher(for: AppNotification.Push.analysisResult)
            .compactMap { [dateFormatter] notification -> AnalysisResultNotification? in
                guard let userInfo = notification.userInfo,
                      let uploadId = userInfo[AppNotification.Push.Key.uploadId] as? String,
                      let dateString = userInfo[AppNotification.Push.Key.date] as? String,
                      let date = dateFormatter.date(from: dateString)
                else { return nil }
                return AnalysisResultNotification(uploadId: uploadId, date: date)
            }
            .eraseToAnyPublisher()
    }

    public init() {}
}
