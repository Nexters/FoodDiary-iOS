//
//  MyPageCoordinator.swift
//  Presentation
//

import Combine
import UIKit

public final class MyPageCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start() {
        let vc = factories.myPage.makeScene()
        vc.hidesBottomBarWhenPushed = true
        flowBind(vc: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Screen Routing

private extension MyPageCoordinator {
    func flowBind(vc: MyPageViewController) {
        vc.flowPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .finish:
                    self?.finish()
                }
            }
            .store(in: &cancellables)
    }
}

private extension MyPageCoordinator {
    func finish() {
        parentCoordinator?.removeChild(self)
    }
}
