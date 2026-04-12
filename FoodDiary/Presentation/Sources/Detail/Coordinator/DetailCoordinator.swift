//
//  DetailCoordinator.swift
//  Presentation
//

import UIKit

public final class DetailCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start() {}

    public func start(input: DetailSceneInput) {
        let detailVC = factories.detail.makeDetailScene(
            input: input,
            imagePickerDelegate: self
        )
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - ImagePickerDelegate

extension DetailCoordinator: ImagePickerDelegate {
    public func pushImagePicker(input: ImagePickerSceneInput) {
        let coord = ImagePickerCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }
}
