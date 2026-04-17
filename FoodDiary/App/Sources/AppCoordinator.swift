//
//  AppCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/8/26.
//

import Domain
import Presentation
import UIKit

final class AppCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []

    weak var sceneTransitioner: SceneTransitioning?
    private let factories: Factories

    init(factories: Factories) {
        self.factories = factories
    }
}

// MARK: - Screen Routing

extension AppCoordinator {
    func pushLoginVC() {
        childCoordinators.removeAll()

        let loginCoordinator = LoginCoordinator(factories: factories)
        loginCoordinator.sceneTransitioner = sceneTransitioner
        loginCoordinator.parentCoordinator = self
        addChild(loginCoordinator)

        loginCoordinator.start()
    }

    func pushMainVC() {
        childCoordinators.removeAll()

        let mainCoordinator = MainCoordinator(factories: factories)
        mainCoordinator.sceneTransitioner = sceneTransitioner
        mainCoordinator.parentCoordinator = self
        addChild(mainCoordinator)

        mainCoordinator.start()
    }

    func navigateToDetail(diaryDateString: String) {
        performDeepLinkNavigation(diaryDateString: diaryDateString)
    }
}

// MARK: - Deep Link Navigation

extension AppCoordinator {
    private static let deepLinkDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private func performDeepLinkNavigation(diaryDateString: String) {
        guard let date = Self.deepLinkDateFormatter.date(from: diaryDateString) else {
            print("[DeepLink] 날짜 파싱 실패: \(diaryDateString)")
            return
        }

        let navController = childCoordinators
            .compactMap({ $0 as? MainCoordinator })
            .last?.navigationController

        let input = DetailSceneInput(date: date, records: [])
        let coord = DetailCoordinator(factories: factories, navigationController: navController)
        coord.parentCoordinator = self
        addChild(coord)

        if let presented = navController?.presentedViewController {
            presented.dismiss(animated: false) {
                coord.start(input: input)
            }
        } else {
            coord.start(input: input)
        }
    }
}
