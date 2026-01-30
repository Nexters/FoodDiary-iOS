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
                "UIAppFonts": [
                    "Pretendard-Regular.otf",
                    "Pretendard-SemiBold.otf"
                ]
            ]
        )
    }
}
