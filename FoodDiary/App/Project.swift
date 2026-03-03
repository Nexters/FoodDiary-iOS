//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    settings: .makeSettings(),
    targets: [
        .target(
            name: "App",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.fooddiary.ios.app",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .sceneDelegateApp(),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "App.entitlements",
            dependencies: [
                .project(target: "Data", path: "../Data"),
                .project(target: "DesignSystem", path: "../DesignSystem"),
                .project(target: "DI", path: "../DI"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Presentation", path: "../Presentation"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseMessaging"),
            ],
            settings: .settings(
                base: [
                    "MARKETING_VERSION": "1.0.0",
                    "BASE_URL": "$(BASE_URL)",
                    "TARGETED_DEVICE_FAMILY": "1"
                ],
                configurations: []
            )
        )
    ],
    schemes: Scheme.makeSchemes()
)
