//
//  ImageRepositoryImpl.swift
//  Data
//

import Domain
import Photos
import UIKit

public struct UIImageLoader: RenderableImageRepository {
    private let imageConverter: PHAssetConverter

    public init(imageLoader: PHAssetConverter) {
        self.imageConverter = imageLoader
    }

    public func loadImage(for asset: PHAsset, targetSize: CGSize, preferFastDelivery: Bool) async throws -> UIImage {
        let deliveryMode: PHImageRequestOptionsDeliveryMode = preferFastDelivery ? .fastFormat : .highQualityFormat
        return try await imageConverter.convert(from: asset, targetSize: targetSize, deliveryMode: deliveryMode)
    }
}
