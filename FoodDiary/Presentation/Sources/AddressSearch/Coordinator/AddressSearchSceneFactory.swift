//
//  AddressSearchSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

// MARK: - Protocol

public protocol AddressSearchSceneProducing {
    func makeScene(input: AddressSearchSceneInput) -> UIViewController
}

// MARK: - Factory

public final class AddressSearchSceneFactory: AddressSearchSceneProducing {
    private let searchAddressUseCase: SearchAddressUseCase<AddressSearchRepositoryImpl>

    public init(searchAddressUseCase: SearchAddressUseCase<AddressSearchRepositoryImpl>) {
        self.searchAddressUseCase = searchAddressUseCase
    }

    public func makeScene(input: AddressSearchSceneInput) -> UIViewController {
        let viewModel = AddressSearchViewModel(
            searchAddressUseCase: searchAddressUseCase,
            diaryId: input.diaryId
        )
        return AddressSearchViewController(
            viewModel: viewModel,
            onAddressSelected: input.onSelected
        )
    }
}
