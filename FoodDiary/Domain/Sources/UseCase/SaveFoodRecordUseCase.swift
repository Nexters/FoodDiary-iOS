//
//  SaveFoodRecordUseCase.swift
//  Domain
//

import Foundation

/// Asset을 서버에 업로드하고 PendingFoodRecord를 반환하는 UseCase
/// 분석 결과는 Remote Push로 수신
public struct SaveFoodRecordUseCase<
    RecordRepo: FoodRecordRepository,
    PendingRepo: PendingFoodRecordRepository
>: Sendable {
    private let repository: RecordRepo
    private let pendingRepository: PendingRepo

    public init(
        repository: RecordRepo,
        pendingRepository: PendingRepo
    ) {
        self.repository = repository
        self.pendingRepository = pendingRepository
    }

    /// 서버 업로드 → 로컬 저장 → PendingFoodRecord 반환
    /// 분석 완료 시 Remote Push로 결과 수신
    public func execute(
        from assets: [any ImageAssetable],
        date: Date
    ) async throws -> PendingFoodRecord {
        let request = CreateFoodRecordRequest(date: date, assets: assets)
        let uploadId = try await repository.uploadRecord(request)

        let pendingRecord = PendingFoodRecord(
            uploadId: uploadId,
            date: date
        )

        // 로컬에 저장해서 앱 재시작 시 복원 가능하도록 함
        try await pendingRepository.save(pendingRecord)

        return pendingRecord
    }
}
