//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Main",
    targets: [
        .makeFeature(.main),
        .makeTestFeature(.main)
    ]
)

