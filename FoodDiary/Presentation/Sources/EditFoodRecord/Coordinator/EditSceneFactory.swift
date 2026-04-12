//
//  EditSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

// MARK: - Factory

public final class EditSceneFactory {
    private typealias RecordRepo = FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>

    private let updateFoodRecordUseCase: UpdateFoodRecordUseCase<RecordRepo>
    private let deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>

    public init(
        updateFoodRecordUseCase: UpdateFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>,
        deleteFoodRecordUseCase: DeleteFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>
    ) {
        self.updateFoodRecordUseCase = updateFoodRecordUseCase
        self.deleteFoodRecordUseCase = deleteFoodRecordUseCase
    }

    public func makeScene(input: EditSceneInput) -> EditFoodRecordViewController<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
    > {
        let viewModel = EditFoodRecordViewModel(
            record: input.record,
            updateFoodRecordUseCase: updateFoodRecordUseCase,
            deleteFoodRecordUseCase: deleteFoodRecordUseCase
        )
        return EditFoodRecordViewController(viewModel: viewModel)
    }
}
