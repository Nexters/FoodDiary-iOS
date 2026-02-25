//
//  FoodImageAssetFetcher.swift
//  Data
//
//  Created by Kai Lee on 1/23/26.
//

import Domain
import Logging
import Photos
import UIKit

/// 사진 라이브러리에서 음식 사진을 시간순으로 가져오는 `Repository` 구현체
public struct FoodImageAssetFetcher<
    FoodClassifier: FoodClassifierRepresentable,
    ImageRepo: RenderableImageRepository
>: FoodImageAssetRepository where ImageRepo.Asset == PHAsset {
    private let foodClassifier: FoodClassifier
    private let imageRepository: ImageRepo
    private let cache: ClassificationCacheManager
    private let imageTargetSize: CGSize
    private let logger = Logger(label: "com.fooddiary.asset-fetcher")

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

    public func fetchFoodImageAssets(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodImageAsset<PHAsset>]] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            logger.error("[Asset Fetch] 사진 라이브러리 권한 없음 (status: \(status.rawValue))")
            throw FoodImageAssetError.notAuthorized
        }

        logger.info("[Asset Fetch] 시작 (\(startDate) ~ \(endDate?.description ?? "nil"))")
        let clock = ContinuousClock()
        let start = clock.now

        let sections = await fetchPhotoSections(from: startDate, to: endDate)
        let totalPhotos = sections.reduce(0) { $0 + $1.assets.count }
        logger.info("[Asset Fetch] 사진 \(totalPhotos)장 / \(sections.count)개 섹션 조회됨")

        let result = try await classifyAllSections(sections)
        let elapsed = clock.now - start
        logger.info("[Asset Fetch] 완료 (소요: \(elapsed))")

        return result
    }

    public func prefetchFoodImageAssets(forWeekContaining date: Date) {
        let calendar = Calendar.current
        guard
            let startOfWeek = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            ),
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)
        else {
            return
        }

        Task(priority: .background) {
            _ = try? await self.fetchFoodImageAssets(from: startOfWeek, to: endOfWeek)
        }
    }
}

public typealias PHFoodImageAsset = FoodImageAsset<PHAsset>

// MARK: - Photo Fetching

extension FoodImageAssetFetcher {
    fileprivate struct PhotoSection {
        let date: Date
        let assets: [PHAsset]
    }

    fileprivate func fetchPhotoSections(from startDate: Date, to endDate: Date?) async
        -> [PhotoSection]
    {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var predicates: [NSPredicate] = [
            NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue),
            NSPredicate(format: "creationDate >= %@", startDate as NSDate),
        ]
        if let end = endDate {
            predicates.append(NSPredicate(format: "creationDate <= %@", end as NSDate))
        }
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let fetchResult = PHAsset.fetchAssets(with: options)
        return groupByDate(fetchResult)
    }

    fileprivate func groupByDate(_ fetchResult: PHFetchResult<PHAsset>) -> [PhotoSection] {
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

extension FoodImageAssetFetcher {
    fileprivate func classifyAllSections(_ sections: [PhotoSection]) async throws -> [Date:
        [PHFoodImageAsset]]
    {
        let results = try await mapEach(sections) { section in
            let photos = try await self.classifyPhotosInSection(section)
            return (section.date, photos)
        }

        return Dictionary(uniqueKeysWithValues: results)
    }

    fileprivate func classifyPhotosInSection(_ section: PhotoSection) async throws
        -> [PHFoodImageAsset]
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        logger.info("[Classify] \(dateFormatter.string(from: section.date)) 섹션 \(section.assets.count)장 분류 시작")
        let clock = ContinuousClock()
        let start = clock.now

        return try await withThrowingTaskGroup(
            of: (originalIndex: Int, photo: PHFoodImageAsset).self
        ) { group in
            for (index, asset) in section.assets.enumerated() {
                group.addTask {
                    (originalIndex: index, photo: try await self.classifyAsset(asset))
                }
            }

            var results: [(originalIndex: Int, photo: PHFoodImageAsset)] = []
            for try await result in group {
                results.append(result)
            }
            let photos = results
                .sorted { $0.originalIndex < $1.originalIndex }
                .map(\.photo)

            let elapsed = clock.now - start
            let foodCount = photos.filter { $0.foodProbability > 0.5 }.count
            logger.info("[Classify] \(dateFormatter.string(from: section.date)) 섹션 완료 - 음식 \(foodCount)/\(photos.count)장 (소요: \(elapsed))")
            return photos
        }
    }

    fileprivate func classifyAsset(_ asset: PHAsset) async throws -> PHFoodImageAsset {
        let identifier = asset.localIdentifier

        if let cached = await cache.get(identifier) {
            logger.trace("[Classify] 캐시 히트 \(identifier) (prob: \(cached.foodProbability))")
            return FoodImageAsset(
                imageAsset: asset,
                foodProbability: cached.foodProbability
            )
        }

        logger.trace("[Classify] 캐시 미스 \(identifier)")
        let image = try await imageRepository.loadImage(
            for: asset,
            targetSize: imageTargetSize,
            preferFastDelivery: true
        )
        let result = try foodClassifier.classify(image: image)
        logger.trace("[Classify] 분류 완료 \(identifier) (prob: \(result.foodProbability))")

        await cache.set(
            .init(
                identifier: identifier,
                foodProbability: result.foodProbability
            ))

        return FoodImageAsset(
            imageAsset: asset,
            foodProbability: result.foodProbability
        )
    }

    fileprivate func mapEach<T, R: Sendable>(
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
