//
//  AppNotification.swift
//  Domain
//

import Foundation

public enum AppNotification {
    public enum Push {
        public static let analysisResult = Notification.Name("AppNotification.Push.analysisResult")
        public static let deepLinkToDetail = Notification.Name("AppNotification.Push.deepLinkToDetail")

        public enum Key {
            public static let type = "type"
            public static let diaryDate = "diaryDate"
        }
    }
}
