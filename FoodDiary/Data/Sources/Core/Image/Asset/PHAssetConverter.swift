//
//  PHImageConverter.swift
//  Data
//

import ImageIO
import Photos
import UIKit
import UniformTypeIdentifiers

public final class PHAssetConverter: @unchecked Sendable {
    private let cachingManager = PHCachingImageManager()

    public init() {}

    public func convert(
        from asset: PHAsset,
        targetSize: CGSize,
        deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = deliveryMode
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

    /// 리사이즈 + 압축된 JPEG Data를 반환하되, 원본 EXIF 메타데이터를 보존
    public func convertToJPEGData(
        from asset: PHAsset,
        targetSize: CGSize,
        compressionQuality: CGFloat = 0.8
    ) async throws -> Data {
        // 1. 원본 Data에서 EXIF 추출
        let originalData = try await requestOriginalData(from: asset)
        let metadata = extractMetadata(from: originalData)

        // 2. 리사이즈된 UIImage 획득
        let resizedImage = try await convert(from: asset, targetSize: targetSize)

        // 3. 리사이즈된 이미지에 원본 EXIF 주입
        return try embedMetadata(metadata, into: resizedImage, compressionQuality: compressionQuality)
    }

    // MARK: - EXIF Helpers

    private func requestOriginalData(from asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            cachingManager.requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, info in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    let isCloudError = (info?[PHImageErrorKey] as? NSError)?.domain == "CloudPhotoLibraryErrorDomain"
                    let error: PHImageLoaderError = isCloudError ? .iCloudDownloadFailed : .imageLoadFailed
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func extractMetadata(from data: Data) -> CFDictionary? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
    }

    private func embedMetadata(
        _ metadata: CFDictionary?,
        into image: UIImage,
        compressionQuality: CGFloat
    ) throws -> Data {
        guard let cgImage = image.cgImage else {
            throw PHImageLoaderError.imageLoadFailed
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw PHImageLoaderError.imageLoadFailed
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]

        // 원본 EXIF 메타데이터 주입 (orientation 제거하여 이중 회전 방지)
        if let metadata = metadata as? [CFString: Any] {
            for (key, value) in metadata {
                properties[key] = value
            }

            // requestImage()가 이미 올바른 방향으로 회전된 이미지를 반환하므로
            // orientation 메타데이터를 제거하여 이중 회전을 방지
            properties.removeValue(forKey: kCGImagePropertyOrientation)

            if var tiffDict = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
                tiffDict.removeValue(forKey: kCGImagePropertyTIFFOrientation)
                properties[kCGImagePropertyTIFFDictionary] = tiffDict
            }
        }

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw PHImageLoaderError.imageLoadFailed
        }

        return mutableData as Data
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
    case iCloudDownloadFailed

    public var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "이미지를 불러올 수 없습니다."
        case .iCloudDownloadFailed:
            return "iCloud에서 원본 이미지를 다운로드할 수 없습니다. 기기에서 직접 촬영한 사진으로 시도해 주세요."
        }
    }
}
