//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription

let project = Project(
    name: "Core",
    targets: [
        .target(
            name: "Core",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.fooddiary.core",
            deploymentTargets: .iOS("18.0"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "TensorFlowLiteSwift"),
            ]
        ),
        .target(
            name: "CoreTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.fooddiary.core.tests",
            deploymentTargets: .iOS("18.0"),
            sources: ["Tests/**"],
            resources: ["Tests/Resources/**"],
            dependencies: [
                .target(name: "Core")
            ]
        )
    ]
)

