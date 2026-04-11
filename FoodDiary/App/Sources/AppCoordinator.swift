//
//  AppCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/8/26.
//

import Combine
import DI
import Data
import Domain
import Presentation
import UIKit

final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    weak var sceneTransitioner: SceneTransitioning?
    private let container: DIContainer
    private let sceneProducer: MainSceneProducer

    var currentNavigationController: UINavigationController? {
        childCoordinators.compactMap { $0 as? MainCoordinator }.last?.navigationController
    }

    init(
        container: DIContainer,
        sceneProducer: MainSceneProducer
    ) {
        self.container = container
        self.sceneProducer = sceneProducer
    }

    func start() {}
}

// MARK: - Screen Routing

extension AppCoordinator {
    func pushLoginVC() {
        let loginCoordinator = LoginCoordinator(sceneProducer: sceneProducer)
        loginCoordinator.sceneTransitioner = sceneTransitioner
        loginCoordinator.parentCoordinator = self
        addChild(loginCoordinator)
        
        loginCoordinator.start()
    }

    func pushMainVC() {
        let mainCoordinator = MainCoordinator(sceneProducer: sceneProducer)
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

        guard let navController = currentNavigationController else {
            print("[DeepLink] NavigationController를 찾을 수 없음")
            return
        }

        typealias DeepLinkDetailVM = DetailViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            PushNotificationObserver
        >
        guard let detailVM = try? container.resolve(DeepLinkDetailVM.self, argument: (date, [FoodRecord]())) else {
            fatalError("DetailViewModel not registered")
        }
        let detailVC = DetailViewController(viewModel: detailVM)

        if let presented = navController.presentedViewController {
            presented.dismiss(animated: false) {
                navController.pushViewController(detailVC, animated: true)
            }
        } else {
            navController.pushViewController(detailVC, animated: true)
        }
    }
}
