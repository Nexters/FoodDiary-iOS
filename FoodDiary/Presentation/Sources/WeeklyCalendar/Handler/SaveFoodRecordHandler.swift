//
//  SaveFoodRecordHandler.swift
//  Presentation
//

import Data
import Domain
import Foundation
import UIKit

struct SaveFoodRecordHandler<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository,
    ImageProvider: RenderableImageRepository
> where ImageProvider.Asset == AssetRepo.Asset {
    struct PendingPreparation {
        let pendingRecord: PendingFoodRecord
        let images: [UIImage]
    }

    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>
    private let imageProvider: ImageProvider

    init(
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>,
        imageProvider: ImageProvider
    ) {
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.imageProvider = imageProvider
    }

    func preparePendingRecord(from assets: [AssetRepo.Asset], date: Date) async throws -> PendingPreparation {
        let images = try await loadImages(from: assets)
        let pendingRecord = PendingFoodRecord(
            date: date,
            representativeImage: images[0]
        )
        return PendingPreparation(pendingRecord: pendingRecord, images: images)
    }

    func saveRecord(date: Date, images: [UIImage]) async throws -> FoodRecord {
        let request = CreateFoodRecordRequest(
            date: date,
            images: images
        )

        return try await BackgroundTaskManager.shared.performBackgroundTask(
            named: "SaveFoodRecord"
        ) { [saveFoodRecordUseCase] in
            try await saveFoodRecordUseCase.execute(request)
        }
    }

    private func loadImages(from assets: [AssetRepo.Asset]) async throws -> [UIImage] {
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
