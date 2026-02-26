//
//  PendingThumbnailRepository.swift
//  Domain
//

import UIKit

public protocol PendingThumbnailRepository: Sendable {
    func loadThumbnail(assetIdentifier: String, targetSize: CGSize) async throws -> UIImage
}
