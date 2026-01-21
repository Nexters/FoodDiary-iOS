//
//  FoodPhotoFetcher.swift
//  Data
//
//  Created by Kai Lee on 1/20/26.
//

import Foundation
import Domain
import Photos
import UIKit


public struct FoodPhotoFetcher<
    PhotoLibrary: PhotoLibraryRepresentable,
    FoodClassifier: FoodClassifierRepresentable
> {
    private let useCase: FoodPhotoFetchUseCase<PhotoLibrary, FoodClassifier>

    public init(
        photoLibrary: PhotoLibrary,
        foodClassifier: FoodClassifier
    ) {
        self.useCase = FoodPhotoFetchUseCase(
            photoLibrary: photoLibrary,
            foodClassifier: foodClassifier
        )
    }

    public func fetchFoodPhotos(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodPhoto]] {
        try await useCase.fetchFoodPhotos(from: startDate, to: endDate)
    }
}
