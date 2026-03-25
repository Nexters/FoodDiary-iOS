//
//  Project+Templates.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import ProjectDescription

public extension ProjectDescription.TargetScript {
    static func crashlyticsUploadDSYM() -> Self {
        .post(
            script: """
                ROOT_PATH="$SRCROOT"
                while [ "$ROOT_PATH" != "/" ]; do
                  if [ -d "$ROOT_PATH/Tuist" ]; then
                    break
                  fi
                  ROOT_PATH=$(dirname "$ROOT_PATH")
                done

                CRASHLYTICS_RUN="${ROOT_PATH}/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run"
                echo "[Crashlytics] ROOT_PATH = ${ROOT_PATH}"
                echo "[Crashlytics] run script path = ${CRASHLYTICS_RUN}"

                if [ -f "$CRASHLYTICS_RUN" ]; then
                  echo "[Crashlytics] ✅ run script found"
                  "$CRASHLYTICS_RUN"
                else
                  echo "[Crashlytics] ❌ run script NOT found at ${CRASHLYTICS_RUN}"
                  exit 1
                fi
                """,
            name: "FirebaseCrashlytics",
            inputPaths: [
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)"
            ],
            basedOnDependencyAnalysis: false
        )
    }
}

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
