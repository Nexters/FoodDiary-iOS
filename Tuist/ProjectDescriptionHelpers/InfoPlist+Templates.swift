//
//  InfoPlist+Templates.swift
//  Manifests
//
//  Created by 강대훈 on 1/14/26.
//

import ProjectDescription

public extension InfoPlist {
    static func sceneDelegateApp() -> InfoPlist {
        .extendingDefault(
            with: [
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "UILaunchStoryboardName": "LaunchScreen",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": [
                            [
                                "UISceneConfigurationName": "Default Configuration",
                                "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                            ]
                        ]
                    ]
                ],
                "UILaunchScreen": [
                    "UIColorName": "",
                    "UIImageName": ""
                ],
                "NSPhotoLibraryUsageDescription": "음식 사진을 분류하기 위해 사진 라이브러리 접근 권한이 필요합니다.",
                "NSUserNotificationsUsageDescription": "음식 분석 완료 알림을 받기 위해 알림 권한이 필요합니다.",
                "BASE_URL": "$(BASE_URL)",
                "NSAppTransportSecurity": [
                    "NSAllowsArbitraryLoads": true
                ],
                "UIBackgroundModes": [
                    "remote-notification"
                ],
                "ITSAppUsesNonExemptEncryption": false,
                "CFBundleDisplayName": "뭐먹었지?",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait"
                ],
                "UIRequiresFullScreen": true
            ]
        )
    }
}
