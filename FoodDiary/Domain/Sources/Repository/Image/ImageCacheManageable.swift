//
//  ImageCacheManageable.swift
//  Data
//
//  Created by Kai Lee on 1/23/26.
//

import UIKit

/// 이미지 캐싱 및 로드를 담당하는 프로토콜
public protocol ImageCacheManageable<Asset>: Sendable {
    associatedtype Asset: ImageAssetable

    /// 이미지 요청
    func requestImage(
        for asset: Asset,
        targetSize: CGSize
    ) async throws -> UIImage

    /// 지정된 asset들을 미리 캐싱
    func startCaching(
        assets: [Asset],
        targetSize: CGSize
    )

    /// 캐싱 중단
    func stopCaching(
        assets: [Asset],
        targetSize: CGSize
    )

    /// 모든 캐싱 중단
    func stopCachingAll()
}
