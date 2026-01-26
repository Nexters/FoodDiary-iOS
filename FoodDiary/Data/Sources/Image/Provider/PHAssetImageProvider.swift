//
//  PHAssetImageProvider.swift
//  Data
//

import Domain
import Photos
import UIKit

/// PHAsset 기반 이미지 제공자
public final class PHAssetImageProvider<
    CacheManager: ImageCacheManageable
>: ImageProviding where CacheManager.Asset == PHAsset {
    private let imageCache: CacheManager

    public init(imageCache: CacheManager) {
        self.imageCache = imageCache
    }

    public func loadImage(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        try await imageCache.requestImage(for: asset, targetSize: targetSize)
    }
}
