//
//  DeletePendingRecordUseCase.swift
//  Domain
//

import Foundation

/// Push 알림으로 분석 완료된 pending 기록 삭제
public struct DeletePendingRecordUseCase<Repo: PendingFoodRecordRepository>: Sendable {
    private let repository: Repo

    public init(repository: Repo) {
        self.repository = repository
    }

    public func execute(uploadIds: [String]) async throws {
        try await repository.delete(byUploadIds: uploadIds)
    }

    public func execute(byDate date: Date) async throws {
        try await repository.delete(byDate: date)
    }
}
