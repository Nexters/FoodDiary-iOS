//
//  ImageProviding.swift
//  Domain
//

import UIKit

public protocol ImageProviding: Sendable {
    /// 지정된 ID의 이미지를 로드합니다.
    /// - Parameters:
    ///   - id: 이미지 식별자
    ///   - targetSize: 요청 이미지 크기
    /// - Returns: 로드된 UIImage
    func loadImage(for id: String, targetSize: CGSize) async throws -> UIImage
}

/// ImageProvider 관련 에러
public enum ImageProviderError: Error {
    case assetNotFound
    case loadFailed
}
