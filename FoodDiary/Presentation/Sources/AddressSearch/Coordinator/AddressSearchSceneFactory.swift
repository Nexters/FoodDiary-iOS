//
//  AddressSearchSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

// MARK: - Factory

public final class AddressSearchSceneFactory {
    private let searchAddressUseCase: SearchAddressUseCase<AddressSearchRepositoryImpl>

    public init(searchAddressUseCase: SearchAddressUseCase<AddressSearchRepositoryImpl>) {
        self.searchAddressUseCase = searchAddressUseCase
    }

    public func makeScene(input: AddressSearchSceneInput) -> AddressSearchViewController<AddressSearchRepositoryImpl> {
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
