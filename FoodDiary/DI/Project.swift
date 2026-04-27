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
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.fooddiary.di",
            deploymentTargets: .iOS("26.0"),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "Swinject"),
            ]
        ),
    ]
)

