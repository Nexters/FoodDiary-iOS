//
//  PendingThumbnailRepositoryImpl.swift
//  Data
//

import Domain
import Photos
import UIKit

public struct PendingThumbnailRepositoryImpl: PendingThumbnailRepository {
    private let imageLoader: UIImageLoader

    public init(imageLoader: UIImageLoader) {
        self.imageLoader = imageLoader
    }

    public func loadThumbnail(assetIdentifier: String, targetSize: CGSize) async throws -> UIImage {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            throw PHImageLoaderError.imageLoadFailed
        }
        return try await imageLoader.loadImage(for: asset, targetSize: targetSize)
    }
}
