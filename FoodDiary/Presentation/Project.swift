//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/16/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Presentation",
    targets: [
        .target(
            name: "Presentation",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.fooddiary.presentation",
            deploymentTargets: .iOS("18.0"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .project(target: "DesignSystem", path: "../DesignSystem"),
                .project(target: "DI", path: "../DI"),
                .external(name: "Kingfisher"),
            ]
        ),
        .target(
            name: "PresentationTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.fooddiary.presentation.tests",
            deploymentTargets: .iOS("18.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "Presentation")
            ]
        )
    ]
)
