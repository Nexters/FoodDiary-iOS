//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription

let project = Project(
    name: "Data",
    targets: [
        .target(
            name: "Data",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.fooddiary.data",
            deploymentTargets: .iOS("18.0"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Domain", path: "../Domain"),
                .external(name: "TensorFlowLiteSwift"),
                .external(name: "Logging"),
            ]
        ),
        .target(
            name: "DataTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.fooddiary.data.tests",
            deploymentTargets: .iOS("18.0"),
            sources: ["Tests/**"],
            resources: ["Tests/Resources/**"],
            dependencies: [
                .target(name: "Data"),
            ]
        ),
    ]
)
