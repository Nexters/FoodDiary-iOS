//
//  MyPageCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/11/26.
//

import Presentation
import UIKit

final class MyPageCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: MainCoordinator?

    private let sceneProducer: MainSceneProducer
    private weak var navigationController: UINavigationController?

    init(sceneProducer: MainSceneProducer, navigationController: UINavigationController) {
        self.sceneProducer = sceneProducer
        self.navigationController = navigationController
    }

    func start() {
        let myPageVC = sceneProducer.makeMyPageScene()
        myPageVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(myPageVC, animated: true)
    }
}
