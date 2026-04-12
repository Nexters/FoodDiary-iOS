//
//  LoginCoordinator.swift
//  Presentation
//

import UIKit

public final class LoginCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?
    public weak var sceneTransitioner: SceneTransitioning?

    private let factories: Factories

    public init(factories: Factories) {
        self.factories = factories
    }

    public func start() {
        let vc = factories.login.makeScene()
        sceneTransitioner?.transition(to: vc)
    }
}
