//
//  BackgroundTaskPerforming.swift
//  Domain
//

import Foundation

public protocol BackgroundTaskPerforming: Sendable {
    /// 백그라운드 작업 수행
    /// - Parameters:
    ///   - name: 작업 이름 (디버깅용)
    ///   - task: 수행할 비동기 작업
    /// - Returns: 작업 결과
    func performBackgroundTask<T: Sendable>(
        named name: String,
        task: @escaping @Sendable () async throws -> T
    ) async throws -> T
}
