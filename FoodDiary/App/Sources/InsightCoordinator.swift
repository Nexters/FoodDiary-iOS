//
//  InsightCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/11/26.
//

import Presentation
import UIKit

final class InsightCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: MainCoordinator?

    private let sceneProducer: MainSceneProducer

    init(sceneProducer: MainSceneProducer) {
        self.sceneProducer = sceneProducer
    }

    func start() {}

    func makeViewController() -> UIViewController {
        sceneProducer.makeInsightScene()
    }
}
