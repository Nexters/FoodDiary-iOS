//
//  LoadPendingThumbnailUseCase.swift
//  Domain
//

import UIKit

public struct LoadPendingThumbnailUseCase<Repository: PendingThumbnailRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(
        from pendingRecords: [PendingFoodRecord],
        targetSize: CGSize
    ) async -> UIImage? {
        guard let assetIdentifier = pendingRecords.first?.assetIdentifier else { return nil }
        return try? await repository.loadThumbnail(
            assetIdentifier: assetIdentifier,
            targetSize: targetSize
        )
    }
}
