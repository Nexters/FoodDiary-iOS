//
//  AddressSearchCoordinator.swift
//  Presentation
//

import UIKit

public final class AddressSearchCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start(input: AddressSearchSceneInput) {
        guard let presentingVC = navigationController?.topViewController else { return }
        let vc = factories.addressSearch.makeScene(input: input)
        presentingVC.present(vc, animated: true)
    }
}
