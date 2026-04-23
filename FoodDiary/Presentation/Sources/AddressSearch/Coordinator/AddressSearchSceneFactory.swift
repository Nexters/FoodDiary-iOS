//
//  AddressSearchSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

// MARK: - Factory

public final class AddressSearchSceneFactory {
    private let searchAddressUseCase: SearchAddressUseCase

    public init(searchAddressUseCase: SearchAddressUseCase) {
        self.searchAddressUseCase = searchAddressUseCase
    }

    public func makeScene(input: AddressSearchSceneInput) -> AddressSearchViewController {
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
