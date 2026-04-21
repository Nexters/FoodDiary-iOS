//
//  PermissionCoordinator.swift
//  Presentation
//

import UIKit

public final class PermissionCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var presentingViewController: UIViewController?

    public init(
        factories: Factories,
        presentingViewController: UIViewController?
    ) {
        self.factories = factories
        self.presentingViewController = presentingViewController
    }

    public func start() {
        let vc = factories.permission.makeScene()
        vc.modalPresentationStyle = .fullScreen
        presentingViewController?.present(vc, animated: true)
    }
}
