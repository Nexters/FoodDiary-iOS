//
//  Project+Templates.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription

public extension ProjectDescription.Settings {
    static func makeSettings() -> Self {
        return .settings(configurations: [
            .debug(name: "Debug", xcconfig: "../../Configs/debug.xcconfig"),
            .release(name: "Release", xcconfig: "../../Configs/release.xcconfig"),
        ])
    }
}

public extension ProjectDescription.Scheme {
    static func makeSchemes() -> [Self] {
        return [
            .scheme(
                name: "debug",
                buildAction: .buildAction(targets: [.target("App")]),
                testAction: .targets([
                    .testableTarget(target: .project(path: "../Core", target: "CoreTests")),
                    .testableTarget(target: .project(path: "../Domain", target: "DomainTests")),
                    .testableTarget(target: .project(path: "../Data", target: "DataTests")),
                    .testableTarget(target: .project(path: "../Presentation", target: "PresentationTests")),
                ], configuration: "Debug"),
                runAction: .runAction(configuration: "Debug")
            ),
            .scheme(
                name: "release",
                buildAction: .buildAction(targets: [.target("App")]),
                runAction: .runAction(configuration: "Release")
            ),
        ]
    }
}
