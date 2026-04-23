//
//  SaveFoodRecordUseCase.swift
//  Domain
//

import Foundation

/// Asset을 서버에 업로드하는 UseCase
/// 분석 결과는 Remote Push로 수신
public struct SaveFoodRecordUseCase: Sendable {
    private let repository: any FoodRecordRepository

    public init(
        repository: any FoodRecordRepository
    ) {
        self.repository = repository
    }

    /// 서버 업로드 수행
    /// 분석 완료 시 Remote Push로 결과 수신
    @discardableResult
    public func execute(
        from assets: [any ImageAssetable],
        date: Date
    ) async throws -> [UploadResult] {
        let request = CreateFoodRecordRequest(date: date, assets: assets)
        return try await repository.uploadRecord(request)
    }
}
