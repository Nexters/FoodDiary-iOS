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
            destinations: .iOS,
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
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Presentation", path: "../Presentation"),
            ]
        )
    ],
    schemes: Scheme.makeSchemes()
)
