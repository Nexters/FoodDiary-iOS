//
//  LoginCoordinator.swift
//  Presentation
//

import UIKit

public final class LoginCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?
    public weak var sceneTransitioner: SceneTransitioning?

    private let factory: any LoginSceneProducing

    public init(factory: any LoginSceneProducing) {
        self.factory = factory
    }

    public func start() {
        let loginVC = factory.makeLoginScene()
        sceneTransitioner?.transition(to: loginVC)
    }
}
