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

    public func loadImage(for asset: any ImageAssetable, targetSize: CGSize, preferFastDelivery: Bool) async throws -> UIImage {
        guard let phAsset = asset as? PHAsset else {
            throw FoodRecordError.imageConversionFailed
        }
        let deliveryMode: PHImageRequestOptionsDeliveryMode = preferFastDelivery ? .fastFormat : .highQualityFormat
        return try await imageConverter.convert(from: phAsset, targetSize: targetSize, deliveryMode: deliveryMode)
    }
}
