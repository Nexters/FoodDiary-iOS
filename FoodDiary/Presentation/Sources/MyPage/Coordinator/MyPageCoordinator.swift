//
//  MyPageCoordinator.swift
//  Presentation
//

import UIKit

public final class MyPageCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factory: any MyPageSceneProducing
    private weak var navigationController: UINavigationController?

    public init(factory: any MyPageSceneProducing, navigationController: UINavigationController?) {
        self.factory = factory
        self.navigationController = navigationController
    }

    public func start() {
        let myPageVC = factory.makeMyPageScene()
        myPageVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(myPageVC, animated: true)
    }
}
