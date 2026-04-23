//
//  DetailSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public final class DetailSceneFactory {
    private let fetchRecordsUseCase: FetchFoodRecordsUseCase
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase
    private let deleteFoodRecordUseCase: DeleteFoodRecordUseCase
    private let pushNotificationObserver: PushNotificationObserver

    public init(
        fetchRecordsUseCase: FetchFoodRecordsUseCase,
        saveFoodRecordUseCase: SaveFoodRecordUseCase,
        deleteFoodRecordUseCase: DeleteFoodRecordUseCase,
        pushNotificationObserver: PushNotificationObserver
    ) {
        self.fetchRecordsUseCase = fetchRecordsUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.deleteFoodRecordUseCase = deleteFoodRecordUseCase
        self.pushNotificationObserver = pushNotificationObserver
    }

    public func makeScene(input: DetailSceneInput) -> DetailViewController {
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
