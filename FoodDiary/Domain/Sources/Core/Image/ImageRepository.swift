//
//  ImageRepository.swift
//  Domain
//

import UIKit

/// 이미지 로딩을 담당하는 Repository 프로토콜
public protocol ImageRepository<Asset>: Sendable {
    associatedtype Asset: ImageAssetable

    /// 지정된 Asset의 이미지를 로드합니다.
    /// - Parameters:
    ///   - asset: 이미지 에셋
    ///   - targetSize: 요청 이미지 크기
    /// - Returns: 로드된 UIImage
    func loadImage(for asset: Asset, targetSize: CGSize) async throws -> UIImage
}
