//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription

let project = Project(
    name: "DesignSystem",
    targets: [
        .target(
            name: "DesignSystem",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.fooddiary.designsystem",
            deploymentTargets: .iOS("18.0"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "SnapKit"),
            ]
        ),
    ]
)
