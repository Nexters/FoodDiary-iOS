//
//  Workspace.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription

let workspace = Workspace(
    name: "Workspace",
    projects: ["FoodDiary/*"],
    schemes: [
        .scheme(
            name: "AllTests",
            testAction: .targets([
                .testableTarget(target: .project(path: "FoodDiary/Domain", target: "DomainTests")),
                .testableTarget(target: .project(path: "FoodDiary/Data", target: "DataTests")),
                .testableTarget(target: .project(path: "FoodDiary/Presentation", target: "PresentationTests")),
            ])
        )
    ]
)
