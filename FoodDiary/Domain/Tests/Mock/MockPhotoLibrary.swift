//
//  MockPhotoLibrary.swift
//  Domain
//
//  Created by Kai Lee on 1/21/26.
//

@testable import Domain
import Photos
import UIKit

final class MockPhotoLibrary: PhotoLibraryRepresentable, @unchecked Sendable {
    var sectionsToReturn: [PhotoSection] = []

    func requestAuthorization() async -> PHAuthorizationStatus {
        .authorized
    }

    func fetchPhotosByDate(from startDate: Date, to endDate: Date?) async throws -> [PhotoSection] {
        return sectionsToReturn
    }

    func loadImage(from asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        // 1x1 빨간색 이미지 반환
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
