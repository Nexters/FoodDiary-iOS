//
//  ImageRepositoryImpl.swift
//  Data
//

import Domain
import Photos
import UIKit

/// PHImageLoader를 감싸는 Repository 구현체
public struct ImageRepositoryImpl: ImageRepository {
    private let imageLoader: PHImageLoader

    public init(imageLoader: PHImageLoader) {
        self.imageLoader = imageLoader
    }

    public func loadImage(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        try await imageLoader.loadImage(for: asset, targetSize: targetSize)
    }
}
