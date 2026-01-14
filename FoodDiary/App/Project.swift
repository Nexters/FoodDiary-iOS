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
            bundleId: "com.fooddiary.app",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .sceneDelegateApp(),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
                .project(target: "Data", path: "../Data"),
                .project(target: "DesignSystem", path: "../DesignSystem"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Main", path: "../Feature/Main"),
            ]
        )
    ],
    schemes: Scheme.makeSchemes()
)
