//
//  LoginCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/10/26.
//

import Presentation
import UIKit

final class LoginCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: AppCoordinator?
    weak var sceneTransitioner: SceneTransitioning?

    private let sceneProducer: MainSceneProducer

    init(sceneProducer: MainSceneProducer) {
        self.sceneProducer = sceneProducer
    }

    func start() {
        let loginVC = sceneProducer.makeLoginScene()
        sceneTransitioner?.transition(to: loginVC)
    }
}
