//
//  PHImageCache.swift
//  Data
//
//  Created by Kai Lee on 1/23/26.
//

import Domain
import Photos
import UIKit

/// PHAsset 이미지 로딩을 위한 캐싱 매니저
public final class PHImageCache: ImageCacheManageable {
    public typealias Asset = PHAsset

    private let cachingManager = PHCachingImageManager()

    public init() {}

    public func requestImage(
        for asset: PHAsset,
        targetSize: CGSize
    ) async throws -> UIImage {
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
                    continuation.resume(throwing: PHImageCacheError.imageLoadFailed)
                }
            }
        }
    }

    public func startCaching(
        assets: [PHAsset],
        targetSize: CGSize
    ) {
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

    public func stopCaching(
        assets: [PHAsset],
        targetSize: CGSize
    ) {
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

    public func stopCachingAll() {
        cachingManager.stopCachingImagesForAllAssets()
    }
}

public enum PHImageCacheError: LocalizedError {
    case imageLoadFailed

    public var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "이미지를 불러올 수 없습니다."
        }
    }
}
