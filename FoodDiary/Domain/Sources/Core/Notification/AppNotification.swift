//
//  AppNotification.swift
//  Domain
//

import Foundation

public enum AppNotification {
    public enum Push {
        public static let analysisResult = Notification.Name("AppNotification.Push.analysisResult")

        public enum Key {
            public static let uploadId = "uploadId"
        }
    }
}
