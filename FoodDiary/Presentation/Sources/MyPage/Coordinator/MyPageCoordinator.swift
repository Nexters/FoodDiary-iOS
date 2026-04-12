//
//  MyPageCoordinator.swift
//  Presentation
//

import UIKit

public final class MyPageCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start() {
        let myPageVC = factories.myPage.makeMyPageScene()
        myPageVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(myPageVC, animated: true)
    }
}
