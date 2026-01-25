//
//  PHAssetImageProvider.swift
//  Data
//

import Domain
import Photos
import UIKit

/// PHAsset 기반 이미지 제공자
public final class PHAssetImageProvider: ImageProviding, @unchecked Sendable {
    private let assets: [String: PHAsset]
    private let imageCache: PHImageCache

    /// PHAssetImageProvider 초기화
    /// - Parameters:
    ///   - photos: FoodPhoto 배열
    ///   - imageCache: 이미지 캐시 매니저
    public init(photos: [FoodPhoto<PHAsset>], imageCache: PHImageCache) {
        self.assets = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0.imageAsset) })
        self.imageCache = imageCache
    }

    public func loadImage(for id: String, targetSize: CGSize) async throws -> UIImage {
        guard let asset = assets[id] else {
            throw ImageProviderError.assetNotFound
        }
        return try await imageCache.requestImage(for: asset, targetSize: targetSize)
    }
}
