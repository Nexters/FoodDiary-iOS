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
                ]
            ]
        )
    }
}
