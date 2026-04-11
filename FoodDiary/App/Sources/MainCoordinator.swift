//
//  MainCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/10/26.
//

import Combine
import Presentation
import UIKit

final class MainCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var parentCoordinator: (any Coordinator)?
    weak var sceneTransitioner: SceneTransitioning?

    private let factories: Factories
    private var cancellables = Set<AnyCancellable>()

    init(factories: Factories) {
        self.factories = factories
    }

    func start() {
        let calendarCoordinator = CalendarCoordinator(factory: factories.calendar)
        let insightCoordinator = InsightCoordinator(factory: factories.insight)

        calendarCoordinator.parentCoordinator = self
        insightCoordinator.parentCoordinator = self
        addChild(calendarCoordinator)
        addChild(insightCoordinator)

        let calendarVC = calendarCoordinator.makeViewController()
        let insightVC = insightCoordinator.makeViewController()

        let tabBarController = RootTabBarController(calendarVC: calendarVC, insightVC: insightVC)

        tabBarController.mypageButtonTapPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.pushMyPageVC()
            }
            .store(in: &cancellables)

        let navController = makeNavigationController(root: tabBarController)
        sceneTransitioner?.transition(to: navController)
    }
}

extension MainCoordinator {
    func pushMyPageVC() {
        let navController = (childCoordinators.first { $0 is CalendarCoordinator } as? CalendarCoordinator)?.navigationController
        let myPageCoordinator = MyPageCoordinator(factory: factories.myPage, navigationController: navController)
        myPageCoordinator.parentCoordinator = self
        addChild(myPageCoordinator)
        myPageCoordinator.start()
    }
}

private extension MainCoordinator {
    func makeNavigationController(root: UIViewController) -> UINavigationController {
        let navController = UINavigationController(rootViewController: root)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor(white: 1, alpha: 1)]
        appearance.shadowColor = .clear
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.tintColor = UIColor(white: 1, alpha: 1)
        return navController
    }
}
