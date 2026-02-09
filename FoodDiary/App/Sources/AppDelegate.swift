//
//  AppDelegate.swift
//  App
//
//  Created by 강대훈 on 1/12/26.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAppearance()
        registerForRemoteNotifications(application)
        return true
    }

    private func setupAppearance() {
        UINavigationBar.appearance().tintColor = .white
    }

    private func registerForRemoteNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[AppDelegate] Device Token: \(token)")
        // TODO: 서버 API로 토큰 전송
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate] Failed to register for remote notifications: \(error)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handlePushNotification(response.notification.request.content.userInfo)
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handlePushNotification(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }

    private func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        guard let uploadId = userInfo["uploadId"] as? String else { return }
        NotificationCenter.default.post(
            name: .analysisResultReceived,
            object: nil,
            userInfo: ["uploadId": uploadId]
        )
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let analysisResultReceived = Notification.Name("analysisResultReceived")
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
}

