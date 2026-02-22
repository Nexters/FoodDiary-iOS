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
                runAction: .runAction(configuration: "Debug")
            ),
            .scheme(
                name: "release",
                buildAction: .buildAction(targets: [.target("App")]),
                runAction: .runAction(configuration: "Release"),
                archiveAction: .archiveAction(configuration: "Release")
            ),
        ]
    }
}
