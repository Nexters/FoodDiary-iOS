//
//  CleanUpExpiredPendingRecordsUseCase.swift
//  Domain
//

import Foundation

/// 만료되었거나 이미 서버에 분석 완료된 pending 기록을 정리하는 UseCase
public struct CleanUpExpiredPendingRecordsUseCase<
    Repo: PendingFoodRecordRepository
>: Sendable {
    private let repository: Repo
    private let expirationInterval: TimeInterval

    public init(
        repository: Repo,
        expirationInterval: TimeInterval = 300
    ) {
        self.repository = repository
        self.expirationInterval = expirationInterval
    }

    /// 서버 기록과 비교하여 이미 완료된 pending + 만료된 pending을 삭제하고, 유효한 pending만 반환
    public func execute(
        serverRecords: [FoodRecord],
        pendingRecords: [PendingFoodRecord],
        now: Date = Date()
    ) async throws -> [PendingFoodRecord] {
        let completedMealTypes = Set(serverRecords.map(\.mealType))

        var expiredUploadIds: [String] = []
        var validRecords: [PendingFoodRecord] = []

        for record in pendingRecords {
            let isServerCompleted = completedMealTypes.contains(record.mealType)
            let isExpired = now.timeIntervalSince(record.createdAt) >= expirationInterval

            if isServerCompleted || isExpired {
                expiredUploadIds.append(record.uploadId)
            } else {
                validRecords.append(record)
            }
        }

        if !expiredUploadIds.isEmpty {
            try await repository.delete(byUploadIds: expiredUploadIds)
        }

        return validRecords
    }
}
