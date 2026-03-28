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
                echo "===== 🔍 DEBUG START ====="

                # 1. ROOT PATH
                ROOT_PATH="$(cd "$SRCROOT/../.." && pwd)"
                echo "[1] ROOT_PATH: >>>${ROOT_PATH}<<<"

                # 공백 체크
                if [[ "$ROOT_PATH" =~ [[:space:]] ]]; then
                  echo "[WARN] ROOT_PATH contains whitespace"
                else
                  echo "[OK] ROOT_PATH has no whitespace"
                fi

                # 2. CRASHLYTICS PATH
                CRASHLYTICS_PATH="${ROOT_PATH}/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run"
                echo "[2] CRASHLYTICS_PATH: >>>${CRASHLYTICS_PATH}<<<"

                # 개행/공백 체크 (눈으로 보이게)
                echo "[CHECK] Printing with cat -A (hidden chars)"
                echo "$CRASHLYTICS_PATH" | cat -A

                # 3. 파일 존재 여부
                if [ -e "$CRASHLYTICS_PATH" ]; then
                  echo "[OK] File exists"
                else
                  echo "[ERROR] File does NOT exist"
                fi

                # 4. 파일 타입
                if [ -f "$CRASHLYTICS_PATH" ]; then
                  echo "[OK] It is a regular file"
                else
                  echo "[ERROR] Not a regular file"
                fi

                # 5. 실행 권한 체크
                if [ -x "$CRASHLYTICS_PATH" ]; then
                  echo "[OK] File is executable"
                else
                  echo "[ERROR] File is NOT executable"
                fi

                # 6. 권한 상세 출력
                echo "[INFO] ls -l result:"
                ls -l "$CRASHLYTICS_PATH" 2>/dev/null || echo "[ERROR] ls failed"

                # 7. 실제 실행 시도
                echo "[RUN] Trying to execute..."
                "$CRASHLYTICS_PATH"
                RESULT=$?

                echo "[RESULT] Exit code: $RESULT"

                # 8. dirname / basename 체크 (경로 깨짐 확인용)
                echo "[INFO] dirname: $(dirname "$CRASHLYTICS_PATH")"
                echo "[INFO] basename: $(basename "$CRASHLYTICS_PATH")"

                echo "===== 🔍 DEBUG END ====="
                """,
            name: "FirebaseCrashlytics",
            inputPaths: [
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)"
            ],
            basedOnDependencyAnalysis: true
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
