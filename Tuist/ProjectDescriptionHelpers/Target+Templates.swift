//
//  Target+Templates.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription

public extension Target {
    static func makeFeature(_ feature: Module.Feature) -> Target {
        return .target(
            name: feature.capitalized,
            destinations: .iOS,
            product: .framework,
            bundleId: "com.fooddiary.\(feature.rawValue)",
            deploymentTargets: .iOS("18.0"),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DesignSystem", path: "../../DesignSystem"),
            ]
        )
    }
    
    static func makeTestFeature(_ feature: Module.Feature) -> Target {
        return .target(
            name: "\(feature.capitalized)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.fooddiary.\(feature.rawValue).tests",
            deploymentTargets: .iOS("18.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: feature.capitalized),
            ]
        )
    }
}
