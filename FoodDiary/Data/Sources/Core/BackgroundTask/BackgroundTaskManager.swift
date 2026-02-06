//
//  BackgroundTaskManager.swift
//  Data
//

import UIKit

public final class BackgroundTaskManager: @unchecked Sendable {
    public static let shared = BackgroundTaskManager()

    private init() {}

    /// 백그라운드 작업 수행
    /// - Parameters:
    ///   - name: 작업 이름 (디버깅용)
    ///   - task: 수행할 비동기 작업
    /// - Returns: 작업 결과
    public func performBackgroundTask<T: Sendable>(
        named name: String,
        task: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let taskID = await beginBackgroundTask(named: name)

        do {
            let result = try await task()
            await endBackgroundTask(taskID)
            return result
        } catch {
            await endBackgroundTask(taskID)
            throw error
        }
    }

    @MainActor
    private func beginBackgroundTask(named name: String) -> UIBackgroundTaskIdentifier {
        var taskID: UIBackgroundTaskIdentifier = .invalid

        taskID = UIApplication.shared.beginBackgroundTask(withName: name) {
            // 시간 초과 시 작업 종료
            if taskID != .invalid {
                UIApplication.shared.endBackgroundTask(taskID)
            }
        }

        return taskID
    }

    @MainActor
    private func endBackgroundTask(_ taskID: UIBackgroundTaskIdentifier) {
        if taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
        }
    }
}
