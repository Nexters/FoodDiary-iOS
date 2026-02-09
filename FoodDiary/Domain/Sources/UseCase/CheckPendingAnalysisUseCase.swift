//
//  CheckPendingAnalysisUseCase.swift
//  Domain
//

import Foundation

/// Pending 기록들의 분석 결과를 확인하고 완료된 것 처리
public struct CheckPendingAnalysisUseCase<
    PendingRepo: PendingFoodRecordRepository,
    AnalysisRepo: AnalysisResultRepository
>: Sendable {
    private let pendingRepository: PendingRepo
    private let analysisRepository: AnalysisRepo

    public init(
        pendingRepository: PendingRepo,
        analysisRepository: AnalysisRepo
    ) {
        self.pendingRepository = pendingRepository
        self.analysisRepository = analysisRepository
    }

    public struct Result: Sendable {
        public let completedRecords: [(uploadId: String, record: FoodRecord)]
        public let failedUploadIds: [(uploadId: String, reason: String)]
        public let stillPendingUploadIds: [String]

        public init(
            completedRecords: [(uploadId: String, record: FoodRecord)],
            failedUploadIds: [(uploadId: String, reason: String)],
            stillPendingUploadIds: [String]
        ) {
            self.completedRecords = completedRecords
            self.failedUploadIds = failedUploadIds
            self.stillPendingUploadIds = stillPendingUploadIds
        }
    }

    public func execute(for uploadIds: [String]) async throws -> Result {
        guard !uploadIds.isEmpty else {
            return Result(completedRecords: [], failedUploadIds: [], stillPendingUploadIds: [])
        }

        let statuses = try await analysisRepository.fetchResults(for: uploadIds)

        var completedRecords: [(uploadId: String, record: FoodRecord)] = []
        var failedUploadIds: [(uploadId: String, reason: String)] = []
        var stillPendingUploadIds: [String] = []
        var toDeleteUploadIds: [String] = []

        for (uploadId, status) in statuses {
            switch status {
            case .completed(let record):
                completedRecords.append((uploadId: uploadId, record: record))
                toDeleteUploadIds.append(uploadId)
            case .failed(let reason):
                failedUploadIds.append((uploadId: uploadId, reason: reason))
                toDeleteUploadIds.append(uploadId)
            case .pending:
                stillPendingUploadIds.append(uploadId)
            }
        }

        if !toDeleteUploadIds.isEmpty {
            try await pendingRepository.delete(byUploadIds: toDeleteUploadIds)
        }

        return Result(
            completedRecords: completedRecords,
            failedUploadIds: failedUploadIds,
            stillPendingUploadIds: stillPendingUploadIds
        )
    }
}
