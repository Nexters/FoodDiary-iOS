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
import Data
import DI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
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
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("[Push] didReceiveRemoteNotification 호출됨")
        handlePushNotification(userInfo)
        completionHandler(.newData)
    }

    private func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        print("[Push] 수신된 userInfo: \(userInfo)")

        guard let type = userInfo["type"] as? String,
              let diaryDate = userInfo["diary_date"] as? String
        else {
            print("[Push] 파싱 실패 - type 또는 diary_date 누락")
            return
        }

        print("[Push] 파싱 성공 - type: \(type), diary_date: \(diaryDate)")

        NotificationCenter.default.post(
            name: AppNotification.Push.analysisResult,
            object: nil,
            userInfo: [
                AppNotification.Push.Key.type: type,
                AppNotification.Push.Key.diaryDate: diaryDate
            ]
        )
        print("[Push] NotificationCenter로 전달 완료")
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
        completionHandler([])
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        print("[FCM] 토큰 수신: \(fcmToken)")

        // TODO: 서버 API로 fcmToken 전송
        // TODO: self.container로 사용해야 함.
        try? DIContainer.shared.resolve(PushTokenStoring.self).set(fcmToken)
    }
}


