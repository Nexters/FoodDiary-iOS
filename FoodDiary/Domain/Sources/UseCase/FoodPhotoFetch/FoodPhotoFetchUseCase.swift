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
    private let threshold: Float

    public init(
        photoLibrary: PhotoLibrary,
        foodClassifier: FoodClassifier,
        threshold: Float = 0.75
    ) {
        self.photoLibrary = photoLibrary
        self.foodClassifier = foodClassifier
        self.threshold = threshold
    }

    public func fetchFoodPhotos(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [FoodPhotoSection] {
        let sections = try await photoLibrary.fetchPhotosByDate(from: startDate, to: endDate)

        return try await withThrowingTaskGroup(of: FoodPhotoSection.self) { group in
            for section in sections {
                group.addTask {
                    try await self.processFoodPhotosInSection(section)
                }
            }

            var foodPhotoSections: [FoodPhotoSection] = []
            for try await section in group {
                if !section.photos.isEmpty {
                    foodPhotoSections.append(section)
                }
            }

            return foodPhotoSections
        }
    }
}

private extension FoodPhotoFetchUseCase {
    func processFoodPhotosInSection(_ section: PhotoSection) async throws -> FoodPhotoSection {
        let foodPhotos = try await withThrowingTaskGroup(of: FoodPhoto?.self) { group in
            for asset in section.photos {
                group.addTask {
                    try await self.classifyAsset(asset)
                }
            }

            var results: [FoodPhoto] = []
            for try await photo in group {
                if let photo {
                    results.append(photo)
                }
            }

            return results.sorted { $0.confidenceScore > $1.confidenceScore }
        }

        return FoodPhotoSection(date: section.date, photos: foodPhotos)
    }

    func classifyAsset(_ asset: PHAsset) async throws -> FoodPhoto? {
        let image = try await photoLibrary.loadImage(
            from: asset,
            targetSize: CGSize(width: 224, height: 224)
        )
        let result = try foodClassifier.classify(image: image)

        if case let .food(confidence) = result, confidence >= threshold {
            return FoodPhoto(asset: asset, confidenceScore: confidence)
        }

        return nil
    }
}
