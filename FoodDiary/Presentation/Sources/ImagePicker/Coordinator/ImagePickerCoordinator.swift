//
//  ImagePickerCoordinator.swift
//  Presentation
//

import Domain
import UIKit

// MARK: - Coordinator

public final class ImagePickerCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start(input: ImagePickerSceneInput) {
        let vc = factories.imagePicker.makeScene(input: input)
        navigationController?.pushViewController(vc, animated: true)
    }
}
