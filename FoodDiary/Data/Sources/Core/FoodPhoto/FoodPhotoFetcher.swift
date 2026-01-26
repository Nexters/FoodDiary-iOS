//
//  FoodPhotoAlbumFetcher.swift
//  Data
//
//  Created by Kai Lee on 1/23/26.
//

import Domain
import Photos
import UIKit

/// 사진 라이브러리에서 음식 사진을 가져오는 Repository 구현체
///
/// PHAsset을 직접 반환하여 UI에서 이미지 로드 시 PHCachingImageManager 캐싱 활용
public final class FoodPhotoFetcher<
    FoodClassifier: FoodClassifierRepresentable,
    ImageCacheManager: ImageCacheManageable
>: FoodPhotoRepository where ImageCacheManager.Asset == PHAsset {
    public typealias Asset = PHAsset
    
    private let foodClassifier: FoodClassifier
    private let imageCacheManager: ImageCacheManager
    private let imageTargetSize: CGSize
    private let thumbnailSize: CGSize

    /// - Parameters:
    ///   - foodClassifier: 음식 분류기
    ///   - imageCacheManager: 이미지 캐시 매니저
    ///   - imageTargetSize: ML 분류용 이미지 크기 (기본: 224x224)
    ///   - thumbnailSize: UI 썸네일 캐싱 크기 (기본: 300x300)
    public init(
        foodClassifier: FoodClassifier,
        imageCacheManager: ImageCacheManager,
        imageTargetSize: CGSize = CGSize(width: 224, height: 224),
        thumbnailSize: CGSize = CGSize(width: 300, height: 300)
    ) {
        self.foodClassifier = foodClassifier
        self.imageCacheManager = imageCacheManager
        self.imageTargetSize = imageTargetSize
        self.thumbnailSize = thumbnailSize
    }

    public func requestAuthorization() async -> PhotoAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status.toDomain()
    }

    public func fetchFoodPhotos(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodPhoto<PHAsset>]] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw FoodPhotoAlbumError.notAuthorized
        }

        let sections = await fetchPhotoSections(from: startDate, to: endDate)
        return try await classifyAllSections(sections)
    }
}

public typealias FoodPhotoAsset = FoodPhoto<PHAsset>

// MARK: - Photo Fetching

private extension FoodPhotoFetcher {
    struct PhotoSection {
        let date: Date
        let assets: [PHAsset]
    }

    func fetchPhotoSections(from startDate: Date, to endDate: Date?) async -> [PhotoSection] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var predicates: [NSPredicate] = [
            NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue),
            NSPredicate(format: "creationDate >= %@", startDate as NSDate)
        ]
        if let end = endDate {
            predicates.append(NSPredicate(format: "creationDate <= %@", end as NSDate))
        }
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        return await Task.detached(priority: .userInitiated) {
            let fetchResult = PHAsset.fetchAssets(with: options)
            return self.groupByDate(fetchResult)
        }.value
    }

    func groupByDate(_ fetchResult: PHFetchResult<PHAsset>) -> [PhotoSection] {
        let calendar = Calendar.current
        var sections: [Date: [PHAsset]] = [:]

        fetchResult.enumerateObjects { asset, _, _ in
            guard let creationDate = asset.creationDate else { return }
            let dateKey = calendar.startOfDay(for: creationDate)
            sections[dateKey, default: []].append(asset)
        }

        return sections
            .map { PhotoSection(date: $0.key, assets: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - Classification

private extension FoodPhotoFetcher {
    func classifyAllSections(_ sections: [PhotoSection]) async throws -> [Date: [FoodPhotoAsset]] {
        let results = try await mapEach(sections) { section in
            let photos = try await self.classifyPhotosInSection(section)
            return (section.date, photos)
        }

        // UI 표시용 썸네일 미리 캐싱
        let allAssets = results.flatMap { $0.1.map(\.imageAsset) }
        imageCacheManager.startCaching(
            assets: allAssets,
            targetSize: thumbnailSize
        )

        return Dictionary(uniqueKeysWithValues: results)
    }

    func classifyPhotosInSection(_ section: PhotoSection) async throws -> [FoodPhotoAsset] {
        try await mapEach(section.assets) { asset in
            try await self.classifyAsset(asset)
        }
        .sorted { $0.foodProbability > $1.foodProbability }
    }

    func classifyAsset(_ asset: PHAsset) async throws -> FoodPhotoAsset {
        let image = try await imageCacheManager.requestImage(
            for: asset,
            targetSize: imageTargetSize
        )
        let result = try foodClassifier.classify(image: image)

        return FoodPhoto(
            imageAsset: asset,
            foodProbability: result.foodProbability
        )
    }

    func mapEach<T, R: Sendable>(
        _ items: [T],
        transform: @escaping @Sendable (T) async throws -> R
    ) async throws -> [R] {
        try await withThrowingTaskGroup(of: R.self) { group in
            for item in items {
                group.addTask { try await transform(item) }
            }

            var results: [R] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// MARK: - Error

public enum FoodPhotoAlbumError: LocalizedError {
    case notAuthorized
    case imageLoadFailed

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "사진 라이브러리 접근 권한이 없습니다."
        case .imageLoadFailed:
            return "이미지를 불러올 수 없습니다."
        }
    }
}

// MARK: - PHAuthorizationStatus Extension

private extension PHAuthorizationStatus {
    func toDomain() -> PhotoAuthorizationStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .denied
        }
    }
}
