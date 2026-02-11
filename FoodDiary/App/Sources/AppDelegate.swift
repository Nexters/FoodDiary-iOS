//
//  AppDelegate.swift
//  App
//
//  Created by 강대훈 on 1/12/26.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import Domain

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("[AppDelegate] didFinishLaunchingWithOptions")
        FirebaseApp.configure()
        print("[AppDelegate] Firebase configured")
        Messaging.messaging().delegate = self
        setupAppearance()
        registerForRemoteNotifications(application)
        return true
    }

    private func setupAppearance() {
        UINavigationBar.appearance().tintColor = .white
    }

    private func registerForRemoteNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("[AppDelegate] Push authorization granted: \(granted), error: \(String(describing: error))")
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
        // APNs 토큰을 FCM에 전달
        Messaging.messaging().apnsToken = deviceToken

        let apnsToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[AppDelegate] APNs Token: \(apnsToken)")
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
            name: PushNotificationKey.analysisResult,
            object: nil,
            userInfo: [PushNotificationKey.uploadIdKey: uploadId]
        )
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else {
            print("[AppDelegate] FCM Token is nil")
            return
        }

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

        print("[AppDelegate] ========== FCM Token Info ==========")
        print("[AppDelegate] FCM Token: \(fcmToken)")
        print("[AppDelegate] Device ID: \(deviceId)")
        print("[AppDelegate] =====================================")

        // TODO: 서버 API로 deviceId, fcmToken 전송
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
}

