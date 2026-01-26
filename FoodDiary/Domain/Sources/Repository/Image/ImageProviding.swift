//
//  ImageProviding.swift
//  Domain
//

import UIKit

/// 구체적인 이미지를 제공하는 프로토콜
public protocol ImageProviding<Asset>: Sendable {
    associatedtype Asset: ImageAssetable
    /// 지정된 Asset의 이미지를 로드합니다.
    /// - Parameters:
    ///   - asset: 이미지 에셋
    ///   - targetSize: 요청 이미지 크기
    /// - Returns: 로드된 UIImage
    func loadImage(for asset: Asset, targetSize: CGSize) async throws -> UIImage
}
