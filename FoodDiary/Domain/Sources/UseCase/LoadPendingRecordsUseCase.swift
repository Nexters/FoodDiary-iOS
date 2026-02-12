//
//  LoadPendingRecordsUseCase.swift
//  Domain
//

import Foundation

/// 앱 시작 시 저장된 pending 기록 복원
public struct LoadPendingRecordsUseCase<Repo: PendingFoodRecordRepository>: Sendable {
    private let repository: Repo

    public init(repository: Repo) {
        self.repository = repository
    }

    public func execute() async throws -> [PendingFoodRecord] {
        try await repository.fetchAll()
    }
}
