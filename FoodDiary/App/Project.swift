//
//  Project.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    settings: .makeSettings(),
    targets: [
        .target(
            name: "App",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.fooddiary.ios.app",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .sceneDelegateApp(),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: "App.entitlements",
            scripts: [
                .post(
                    script: """
                    if [[ "$(uname -m)" == arm64 ]]; then
                        export PATH="/opt/homebrew/bin:$PATH"
                    fi
                    if which sentry-cli >/dev/null; then
                        export SENTRY_ORG=mumuk-cs
                        export SENTRY_PROJECT=mumuk-ios
                        export SENTRY_AUTH_TOKEN="${SENTRY_AUTH_TOKEN}"
                        ERROR=$(sentry-cli debug-files upload "$DWARF_DSYM_FOLDER_PATH" 2>&1 >/dev/null)
                        if [ ! $? -eq 0 ]; then
                            echo "warning: sentry-cli - $ERROR"
                        fi
                    else
                        echo "warning: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
                    fi
                    """,
                    name: "Upload dSYM to Sentry"
                )
            ],
            dependencies: [
                .project(target: "Data", path: "../Data"),
                .project(target: "DesignSystem", path: "../DesignSystem"),
                .project(target: "DI", path: "../DI"),
                .project(target: "Domain", path: "../Domain"),
                .project(target: "Presentation", path: "../Presentation"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseMessaging"),
                .external(name: "Sentry"),
            ],
            settings: .settings(
                base: [
                    "MARKETING_VERSION": "1.1.0",
                    "CURRENT_PROJECT_VERSION": "26050725",
                    "BASE_URL": "$(BASE_URL)",
                    "SENTRY_DSN": "$(SENTRY_DSN)",
                    "TARGETED_DEVICE_FAMILY": "1"
                ],
                configurations: []
            )
        )
    ],
    schemes: Scheme.makeSchemes()
)
