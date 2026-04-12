//
//  DetailSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public protocol DetailSceneProducing {
    func makeDetailScene(input: DetailSceneInput) -> UIViewController
}

public final class DetailSceneFactory: DetailSceneProducing {
    private typealias RecordRepo = FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>

    private let fetchRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>
    private let deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>
    private let pushNotificationObserver: PushNotificationObserver

    public init(
        fetchRecordsUseCase: FetchFoodRecordsUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>,
        deleteFoodRecordUseCase: DeleteFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>,
        pushNotificationObserver: PushNotificationObserver
    ) {
        self.fetchRecordsUseCase = fetchRecordsUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.deleteFoodRecordUseCase = deleteFoodRecordUseCase
        self.pushNotificationObserver = pushNotificationObserver
    }

    public func makeDetailScene(input: DetailSceneInput) -> UIViewController {
        let viewModel = DetailViewModel(
            initialDate: input.date,
            initialRecords: input.records,
            fetchRecordsUseCase: fetchRecordsUseCase,
            saveFoodRecordUseCase: saveFoodRecordUseCase,
            deleteFoodRecordUseCase: deleteFoodRecordUseCase,
            pushNotificationObserver: pushNotificationObserver
        )
        return DetailViewController(
            viewModel: viewModel,
            initialScrollTarget: input.scrollToMealType,
            shouldPopToRoot: input.shouldPopToRoot,
            onDismissWithDate: input.onDismissWithDate
        )
    }
}
