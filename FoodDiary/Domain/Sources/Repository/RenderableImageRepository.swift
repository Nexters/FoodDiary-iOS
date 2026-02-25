//
//  ImageRepository.swift
//  Domain
//

import UIKit

/// 이미지 로딩을 담당하는 Repository 프로토콜
public protocol RenderableImageRepository<Asset>: Sendable {
    associatedtype Asset: ImageAssetable

    /// 지정된 Asset의 이미지를 로드합니다.
    /// - Parameters:
    ///   - asset: 이미지 에셋
    ///   - targetSize: 요청 이미지 크기
    ///   - preferFastDelivery: true이면 품질보다 속도를 우선합니다 (ML 전처리 등)
    /// - Returns: 로드된 UIImage
    func loadImage(for asset: Asset, targetSize: CGSize, preferFastDelivery: Bool) async throws -> UIImage
}

extension RenderableImageRepository {
    public func loadImage(for asset: Asset, targetSize: CGSize) async throws -> UIImage {
        try await loadImage(for: asset, targetSize: targetSize, preferFastDelivery: false)
    }
}
