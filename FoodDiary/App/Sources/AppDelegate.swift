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
        logBuildConfiguration()
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        setupAppearance()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    private func logBuildConfiguration() {
        #if DEBUG
        print("[App] 빌드 설정: DEBUG")
        #else
        print("[App] 빌드 설정: RELEASE")
        #endif
    }

    private func setupAppearance() {
        UINavigationBar.appearance().tintColor = .white
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

        let applicationState = UIApplication.shared.applicationState

        // 앱 내부 이벤트 전파 (데이터 갱신 + 포그라운드 토스트)
        NotificationCenter.default.post(
            name: AppNotification.Push.analysisResult,
            object: nil,
            userInfo: [
                AppNotification.Push.Key.type: type,
                AppNotification.Push.Key.diaryDate: diaryDate
            ]
        )
        print("[Push] NotificationCenter로 전달 완료")

        // 백그라운드/종료 상태일 때 로컬 알림 배너 표시
        if applicationState != .active {
            scheduleLocalNotification(type: type, diaryDate: diaryDate)
        }
    }

    private func scheduleLocalNotification(type: String, diaryDate: String) {
        let content = UNMutableNotificationContent()
        content.title = "뭐먹었지?"
        content.body = "AI가 기록을 완료했습니다!"
        content.sound = .default
        content.userInfo = [
            "type": type,
            "diary_date": diaryDate,
            "is_local_notification": true
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "analysis_complete_\(diaryDate)"

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if userInfo["is_local_notification"] as? Bool == true {
            // 로컬 알림 탭 → 딥링크로 상세 화면 이동
            if let diaryDate = userInfo["diary_date"] as? String {
                NotificationCenter.default.post(
                    name: AppNotification.Push.deepLinkToDetail,
                    object: nil,
                    userInfo: [AppNotification.Push.Key.diaryDate: diaryDate]
                )
            }
        } else {
            handlePushNotification(userInfo)
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        if userInfo["is_local_notification"] as? Bool == true {
            // 로컬 알림이 포그라운드에서 도착 → 배너 표시 안 함 (토스트로 이미 처리됨)
            completionHandler([])
        } else {
            handlePushNotification(userInfo)
            completionHandler([])
        }
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

