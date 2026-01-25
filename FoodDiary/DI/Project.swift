//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/23/26.
//

import ProjectDescription

let project = Project(
    name: "DI",
    targets: [
        .target(
            name: "DI",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.fooddiary.di",
            deploymentTargets: .iOS("18.0"),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "Swinject"),
            ]
        ),
    ]
)

