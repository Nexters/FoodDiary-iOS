//
//  EditSceneFactory.swift
//  Presentation
//

import Data
import DI
import UIKit

// MARK: - Protocol

public protocol EditSceneProducing {
    func makeScene(input: EditSceneInput) -> UIViewController
}

// MARK: - Factory

public final class EditSceneFactory: EditSceneProducing {
    private typealias EditVM = EditFoodRecordViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
    >

    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
    }

    public func makeScene(input: EditSceneInput) -> UIViewController {
        guard let editVM = try? container.resolve(EditVM.self, argument: input.record) else {
            fatalError("EditFoodRecordViewModel not registered")
        }
        return EditFoodRecordViewController(viewModel: editVM)
    }
}
