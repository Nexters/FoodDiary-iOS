//
//  SaveFoodRecordUseCase.swift
//  Domain
//

import Foundation
import UIKit

/// 이미지 로드 후 서버에 업로드하고 PendingFoodRecord를 반환하는 UseCase
/// 분석 결과는 Remote Push로 수신
public struct SaveFoodRecordUseCase<
    RecordRepo: FoodRecordRepository,
    ImageProvider: RenderableImageRepository
>: Sendable {
    private let repository: RecordRepo
    private let imageProvider: ImageProvider

    public init(
        repository: RecordRepo,
        imageProvider: ImageProvider
    ) {
        self.repository = repository
        self.imageProvider = imageProvider
    }

    /// 이미지 로드 → 서버 업로드 → PendingFoodRecord 반환
    /// 분석 완료 시 Remote Push로 결과 수신
    public func execute(
        from assets: [ImageProvider.Asset],
        date: Date
    ) async throws -> PendingFoodRecord {
        let images = try await loadImages(from: assets)

        let request = CreateFoodRecordRequest(date: date, images: images)
        let uploadId = try await repository.uploadRecord(request)

        return PendingFoodRecord(
            uploadId: uploadId,
            date: date,
            representativeImage: images[0]
        )
    }

    private func loadImages(from assets: [ImageProvider.Asset]) async throws -> [UIImage] {
        try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            for (index, asset) in assets.enumerated() {
                group.addTask {
                    let image = try await imageProvider.loadImage(
                        for: asset,
                        targetSize: CGSize(width: 1200, height: 1200)
                    )
                    return (index, image)
                }
            }

            var results: [(Int, UIImage)] = []
            for try await result in group {
                results.append(result)
            }
            return results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
        }
    }
}
