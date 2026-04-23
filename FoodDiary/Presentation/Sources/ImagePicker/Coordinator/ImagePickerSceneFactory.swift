//
//  ImagePickerSceneFactory.swift
//  Presentation
//

import Data
import Domain
import Photos
import UIKit

// MARK: - Factory

public final class ImagePickerSceneFactory {
    private let imageProvider: UIImageLoader
    private let fetchUseCase: FetchFoodImageAssetUseCase

    public init(
        imageProvider: UIImageLoader,
        fetchUseCase: FetchFoodImageAssetUseCase
    ) {
        self.imageProvider = imageProvider
        self.fetchUseCase = fetchUseCase
    }

    public func makeScene(input: ImagePickerSceneInput) -> ImagePickerViewController {
        let date = input.date
        let fetchUseCase = self.fetchUseCase

        let fetcher: () async throws -> (photos: [any ImageAssetable], preselectedIds: Set<String>) = {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let byDate = try await fetchUseCase.execute(from: startOfDay, to: endOfDay)
            let assets = byDate[startOfDay] ?? []
            let photos = assets.map { $0.imageAsset }
            let preselectedIds = Set(assets.filter { $0.foodProbability >= 0.5 }.map { $0.id })
            return (photos, preselectedIds)
        }

        return ImagePickerViewController(
            imageProvider: imageProvider,
            configuration: .withMaxSelectionCount(10),
            photosFetcher: fetcher,
            onSelected: { assets in input.onSelected(assets) }
        )
    }
}
