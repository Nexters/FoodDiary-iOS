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

        return try await withThrowingTaskGroup(of: (Date, [FoodPhoto]).self) { group in
            for section in sections {
                group.addTask {
                    let photos = try await self.classifyPhotosInSection(section)
                    return (section.date, photos)
                }
            }

            var result: [Date: [FoodPhoto]] = [:]
            for try await (date, photos) in group {
                result[date] = photos
            }

            return result
        }
    }
}

private extension FoodPhotoFetchUseCase {
    /// 섹션 내의 모든 사진을 분류하고 음식 확률 순으로 정렬된 `FoodPhoto` 배열 반환
    func classifyPhotosInSection(_ section: PhotoSection) async throws -> [FoodPhoto] {
        try await withThrowingTaskGroup(of: FoodPhoto.self) { group in
            for asset in section.photos {
                group.addTask {
                    try await self.classifyAsset(asset)
                }
            }

            var results: [FoodPhoto] = []
            for try await photo in group {
                results.append(photo)
            }

            return results.sorted { $0.foodProbability > $1.foodProbability }
        }
    }

    /// `PHAsset`에서 음식 정확도를 판단하고 `FoodPhoto` 객체로 변환
    func classifyAsset(_ asset: PHAsset) async throws -> FoodPhoto {
        let image = try await photoLibrary.loadImage(
            from: asset,
            targetSize: CGSize(width: 224, height: 224)
        )
        let result = try foodClassifier.classify(image: image)

        let foodProbability: Float = switch result {
        case .food(let confidence): confidence
        case .notFood(let confidence): 1.0 - confidence
        }

        return FoodPhoto(asset: asset, foodProbability: foodProbability)
    }
}
