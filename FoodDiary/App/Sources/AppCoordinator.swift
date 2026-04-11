//
//  AppCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/8/26.
//

import DI
import Data
import Domain
import Presentation
import UIKit

final class AppCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []

    weak var sceneTransitioner: SceneTransitioning?
    private let container: DIContainer
    private let factories: Factories

    init(factories: Factories, container: DIContainer) {
        self.factories = factories
        self.container = container
    }

    func start() {}
}

// MARK: - Screen Routing

extension AppCoordinator {
    func pushLoginVC() {
        let loginCoordinator = LoginCoordinator(factory: factories.login)
        loginCoordinator.sceneTransitioner = sceneTransitioner
        loginCoordinator.parentCoordinator = self
        addChild(loginCoordinator)

        loginCoordinator.start()
    }

    func pushMainVC() {
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
            .last?.childCoordinators
            .compactMap({ $0 as? CalendarCoordinator })
            .last?.navigationController

        typealias DeepLinkDetailVM = DetailViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            PushNotificationObserver
        >
        guard let detailVM = try? container.resolve(DeepLinkDetailVM.self, argument: (date, [FoodRecord]())) else {
            fatalError("DetailViewModel not registered")
        }
        let detailVC = DetailViewController(viewModel: detailVM)

        if let presented = navController?.presentedViewController {
            presented.dismiss(animated: false) {
                navController?.pushViewController(detailVC, animated: true)
            }
        } else {
            navController?.pushViewController(detailVC, animated: true)
        }
    }
}
