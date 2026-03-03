//
//  PushNotificationObserver.swift
//  Data
//

import Combine
import Domain
import Foundation

public final class PushNotificationObserver: PushNotificationObserving {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    public var analysisResultPublisher: AnyPublisher<AnalysisResultNotification, Never> {
        NotificationCenter.default.publisher(for: AppNotification.Push.analysisResult)
            .compactMap { [dateFormatter] notification -> AnalysisResultNotification? in
                guard let userInfo = notification.userInfo,
                      let type = userInfo[AppNotification.Push.Key.type] as? String,
                      let dateString = userInfo[AppNotification.Push.Key.diaryDate] as? String,
                      let date = dateFormatter.date(from: dateString)
                else { return nil }
                return AnalysisResultNotification(type: type, diaryDate: date)
            }
            .eraseToAnyPublisher()
    }

    public init() {}
}
