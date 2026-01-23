//
//  FoodPhotoFetchUseCase.swift
//  Data
//
//  Created by Kai Lee on 1/20/26.
//

import Foundation
import Photos
import UIKit

public struct FoodPhotoFetchUseCase<
    PhotoLibrary: PhotoLibraryRepresentable,
    FoodClassifier: FoodClassifierRepresentable
> {
    private let photoLibrary: PhotoLibrary
    private let foodClassifier: FoodClassifier

    public init(
        photoLibrary: PhotoLibrary,
        foodClassifier: FoodClassifier
    ) {
        self.photoLibrary = photoLibrary
        self.foodClassifier = foodClassifier
    }

    public func fetchFoodPhotos(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodPhoto]] {
        let sections = try await photoLibrary.fetchPhotosByDate(from: startDate, to: endDate)
        return try await classifyAllSections(sections)
    }
}

private extension FoodPhotoFetchUseCase {
    /// 모든 섹션을 병렬로 분류하고 날짜별 음식 사진 딕셔너리 반환
    func classifyAllSections(_ sections: [PhotoSection]) async throws -> [Date: [FoodPhoto]] {
        let results = try await mapEach(sections) { section in
            let photos = try await self.classifyPhotosInSection(section)
            return (section.date, photos)
        }
        return Dictionary(uniqueKeysWithValues: results)
    }

    /// 섹션 내의 모든 사진을 분류하고 음식 확률 순으로 정렬된 `FoodPhoto` 배열 반환
    func classifyPhotosInSection(_ section: PhotoSection) async throws -> [FoodPhoto] {
        try await mapEach(section.photos) { phAsset in
            try await self.classifyAsset(phAsset)
        }
        .sorted { $0.foodProbability > $1.foodProbability }
    }

    /// `PHAsset`에서 음식 정확도를 판단하고 `FoodPhoto` 객체로 변환
    func classifyAsset(_ phAsset: PHAsset) async throws -> FoodPhoto {
        let image = try await photoLibrary.loadImage(
            from: phAsset,
            targetSize: CGSize(width: 224, height: 224)
        )
        let result = try foodClassifier.classify(image: image)

        let foodProbability: Float = switch result {
        case .food(let confidence): confidence
        case .notFood(let confidence): 1.0 - confidence
        }

        return FoodPhoto(asset: asset, foodProbability: foodProbability)
    }

    /// 각 요소에 대해 비동기 작업을 병렬로 수행하고 결과 배열 반환
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
