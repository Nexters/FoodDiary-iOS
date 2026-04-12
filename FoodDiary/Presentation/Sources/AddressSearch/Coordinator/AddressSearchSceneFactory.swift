//
//  AddressSearchSceneFactory.swift
//  Presentation
//

import Data
import DI
import Domain
import UIKit

// MARK: - Protocol

public protocol AddressSearchSceneProducing {
    func makeScene(input: AddressSearchSceneInput) -> UIViewController
}

// MARK: - Factory

public final class AddressSearchSceneFactory: AddressSearchSceneProducing {
    private typealias AddressSearchVM = AddressSearchViewModel<AddressSearchRepositoryImpl>

    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
    }

    public func makeScene(input: AddressSearchSceneInput) -> UIViewController {
        guard let addressVM = try? container.resolve(AddressSearchVM.self, argument: input.diaryId) else {
            fatalError("AddressSearchViewModel not registered")
        }
        return AddressSearchViewController(
            viewModel: addressVM,
            onAddressSelected: input.onSelected
        )
    }
}
