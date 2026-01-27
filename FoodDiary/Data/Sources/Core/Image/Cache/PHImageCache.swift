//
//  PHImageLoader.swift
//  Data
//

import Photos
import UIKit

/// PHAsset 기반 이미지 로더 (캐싱 포함)
public final class PHImageLoader: @unchecked Sendable {
    private let cachingManager = PHCachingImageManager()

    public init() {}

    // MARK: - ImageLoading

    public func loadImage(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            cachingManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: PHImageLoaderError.imageLoadFailed)
                }
            }
        }
    }

    // MARK: - Prefetching (Internal)

    func startPrefetching(assets: [PHAsset], targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        cachingManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
    }

    func stopPrefetching(assets: [PHAsset], targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        cachingManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
    }

    func stopAllPrefetching() {
        cachingManager.stopCachingImagesForAllAssets()
    }
}

// MARK: - Error

public enum PHImageLoaderError: LocalizedError {
    case imageLoadFailed

    public var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "이미지를 불러올 수 없습니다."
        }
    }
}
