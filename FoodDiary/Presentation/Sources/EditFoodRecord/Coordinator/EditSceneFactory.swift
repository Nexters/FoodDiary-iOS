//
//  EditSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

// MARK: - Factory

public final class EditSceneFactory {
    private let updateFoodRecordUseCase: UpdateFoodRecordUseCase
    private let deleteFoodRecordUseCase: DeleteFoodRecordUseCase

    public init(
        updateFoodRecordUseCase: UpdateFoodRecordUseCase,
        deleteFoodRecordUseCase: DeleteFoodRecordUseCase
    ) {
        self.updateFoodRecordUseCase = updateFoodRecordUseCase
        self.deleteFoodRecordUseCase = deleteFoodRecordUseCase
    }

    public func makeScene(input: EditSceneInput) -> EditFoodRecordViewController {
        let viewModel = EditFoodRecordViewModel(
            record: input.record,
            updateFoodRecordUseCase: updateFoodRecordUseCase,
            deleteFoodRecordUseCase: deleteFoodRecordUseCase
        )
        return EditFoodRecordViewController(viewModel: viewModel)
    }
}
