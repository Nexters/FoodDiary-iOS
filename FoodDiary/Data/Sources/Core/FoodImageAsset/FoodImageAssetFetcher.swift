//
//  FoodImageAssetFetcher.swift
//  Data
//
//  Created by Kai Lee on 1/23/26.
//

import Domain
import Photos
import UIKit

/// 사진 라이브러리에서 음식 사진을 정확도 높은 순으로 정렬해서 가져오는 `Repository` 구현체
public struct FoodImageAssetFetcher<
    FoodClassifier: FoodClassifierRepresentable,
    ImageRepo: RenderableImageRepository
>: FoodImageAssetRepository where ImageRepo.Asset == PHAsset {
    private let foodClassifier: FoodClassifier
    private let imageRepository: ImageRepo
    private let cache: ClassificationCacheManager
    private let imageTargetSize: CGSize

    /// - Parameters:
    ///   - foodClassifier: 음식 분류기
    ///   - imageRepository: 이미지 레파지토리
    ///   - cache: 분류 결과 캐시
    ///   - imageTargetSize: ML 분류용 이미지 크기 (기본: 224x224)
    public init(
        foodClassifier: FoodClassifier,
        imageRepository: ImageRepo,
        cache: ClassificationCacheManager,
        imageTargetSize: CGSize = CGSize(width: 224, height: 224)
    ) {
        self.foodClassifier = foodClassifier
        self.imageRepository = imageRepository
        self.cache = cache
        self.imageTargetSize = imageTargetSize
    }

    public func authorizationStatus() -> PhotoAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite).toDomain()
    }

    public func requestAuthorization() async -> PhotoAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite).toDomain()
    }

    public func fetchFoodImageAssets(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodImageAsset<PHAsset>]] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw FoodImageAssetError.notAuthorized
        }

        let sections = await fetchPhotoSections(from: startDate, to: endDate)
        return try await classifyAllSections(sections)
    }

    public func prefetchFoodImageAssets(forWeekContaining date: Date) {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        ),
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            return
        }

        Task(priority: .background) {
            _ = try? await self.fetchFoodImageAssets(from: startOfWeek, to: endOfWeek)
        }
    }
}

public typealias PHFoodImageAsset = FoodImageAsset<PHAsset>

// MARK: - Photo Fetching

private extension FoodImageAssetFetcher {
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

        let fetchResult = PHAsset.fetchAssets(with: options)
        return groupByDate(fetchResult)
    }

    func groupByDate(_ fetchResult: PHFetchResult<PHAsset>) -> [PhotoSection] {
        let calendar = Calendar.current
        var sections: [Date: [PHAsset]] = [:]

        fetchResult.enumerateObjects { asset, _, _ in
            guard let creationDate = asset.creationDate else { return }
            let dateKey = calendar.startOfDay(for: creationDate)
            sections[dateKey, default: []].append(asset)
        }

        return sections.map { PhotoSection(date: $0.key, assets: $0.value) }
    }
}

// MARK: - Classification

private extension FoodImageAssetFetcher {
    func classifyAllSections(_ sections: [PhotoSection]) async throws -> [Date: [PHFoodImageAsset]] {
        let results = try await mapEach(sections) { section in
            let photos = try await self.classifyPhotosInSection(section)
            return (section.date, photos)
        }

        return Dictionary(uniqueKeysWithValues: results)
    }

    func classifyPhotosInSection(_ section: PhotoSection) async throws -> [PHFoodImageAsset] {
        try await mapEach(section.assets) { asset in
            try await self.classifyAsset(asset)
        }
        .sorted { $0.foodProbability > $1.foodProbability }
    }

    func classifyAsset(_ asset: PHAsset) async throws -> PHFoodImageAsset {
        let identifier = asset.localIdentifier

        if let cached = await cache.get(identifier) {
            return FoodImageAsset(
                imageAsset: asset,
                foodProbability: cached.foodProbability
            )
        }

        let image = try await imageRepository.loadImage(
            for: asset,
            targetSize: imageTargetSize
        )
        let result = try foodClassifier.classify(image: image)

        await cache.set(.init(
            identifier: identifier,
            foodProbability: result.foodProbability
        ))

        return FoodImageAsset(
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

public enum FoodImageAssetError: LocalizedError {
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

extension PHAuthorizationStatus {
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
