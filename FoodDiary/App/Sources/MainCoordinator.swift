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
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: AppCoordinator?
    weak var sceneTransitioner: SceneTransitioning?

    private let sceneProducer: MainSceneProducer
    private var cancellables = Set<AnyCancellable>()
    private let calendarCoordinator: CalendarCoordinator
    private let insightCoordinator: InsightCoordinator

    var navigationController: UINavigationController? {
        calendarCoordinator.navigationController
    }

    init(sceneProducer: MainSceneProducer) {
        self.sceneProducer = sceneProducer
        self.calendarCoordinator = CalendarCoordinator(sceneProducer: sceneProducer)
        self.insightCoordinator = InsightCoordinator(sceneProducer: sceneProducer)
    }

    func start() {
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
        calendarCoordinator.configure(navigationController: navController)
        sceneTransitioner?.transition(to: navController)
    }
}

extension MainCoordinator {
    func pushMyPageVC() {
        guard let navController = navigationController else { return }
        let myPageCoordinator = MyPageCoordinator(sceneProducer: sceneProducer, navigationController: navController)
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
