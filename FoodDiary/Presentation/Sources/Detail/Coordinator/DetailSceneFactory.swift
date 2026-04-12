//
//  DetailSceneFactory.swift
//  Presentation
//

import Data
import DI
import Domain
import UIKit

public protocol DetailSceneProducing {
    func makeDetailScene(input: DetailSceneInput, imagePickerDelegate: (any ImagePickerDelegate)?) -> UIViewController
}

public final class DetailSceneFactory: DetailSceneProducing {
    private typealias DetailVM = DetailViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
        PushNotificationObserver
    >
    private typealias EditVM = EditFoodRecordViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
    >
    private typealias AddressSearchVM = AddressSearchViewModel<AddressSearchRepositoryImpl>

    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
    }

    public func makeDetailScene(input: DetailSceneInput, imagePickerDelegate: (any ImagePickerDelegate)?) -> UIViewController {
        guard let detailVM = try? container.resolve(DetailVM.self, argument: (input.date, input.records)) else {
            fatalError("DetailViewModel not registered")
        }
        return DetailViewController(
            viewModel: detailVM,
            initialScrollTarget: input.scrollToMealType,
            shouldPopToRoot: input.shouldPopToRoot,
            onDismissWithDate: input.onDismissWithDate,
            editViewControllerFactory: { [weak self] record in
                self?.makeEditViewController(for: record) ?? UIViewController()
            },
            imagePickerDelegate: imagePickerDelegate
        )
    }
}

// MARK: - Private

private extension DetailSceneFactory {
    func makeEditViewController(for record: FoodRecord) -> UIViewController {
        guard let editVM = try? container.resolve(EditVM.self, argument: record) else {
            fatalError("EditFoodRecordViewModel not registered")
        }
        let addressSearchVCFactory: (Int, @escaping (AddressSearchResult) -> Void) -> UIViewController = {
            [container] diaryId, onSelect in
            guard let addressVM = try? container.resolve(AddressSearchVM.self, argument: diaryId) else {
                fatalError("AddressSearchViewModel not registered")
            }
            return AddressSearchViewController(viewModel: addressVM, onAddressSelected: onSelect)
        }
        return EditFoodRecordViewController(
            viewModel: editVM,
            addressSearchViewControllerFactory: addressSearchVCFactory
        )
    }
}
