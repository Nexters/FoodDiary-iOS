//
//  MainSceneProducer.swift
//  App
//
//  Created by 강대훈 on 4/8/26.
//

import DI
import Data
import Domain
import Presentation
import UIKit

final class MainSceneProducer {
    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }
}

// MARK: - Scene Factory

extension MainSceneProducer {
    func makeLoginScene() -> LoginViewController {
        guard let viewModel = try? container.resolve(LoginViewModel.self) else {
            fatalError("LoginViewModel Failed Resolve")
        }
        return LoginViewController(viewModel: viewModel)
    }

    func makeInsightScene() -> UIViewController {
        typealias InsightVM = InsightViewModel<
            InsightRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
        >
        guard let insightVM = try? container.resolve(InsightVM.self) else {
            fatalError("InsightViewModel not registered")
        }
        return InsightViewController(viewModel: insightVM)
    }

    func makeOnboardingScene() -> OnboardingViewController {
        return OnboardingViewController()
    }

    func makeMyPageScene() -> MyPageViewController {
        guard let vm = try? container.resolve(MyPageViewModel.self) else {
            fatalError("MyPageViewModel not registered")
        }
        return MyPageViewController(viewModel: vm)
    }
}

// MARK: - Calendar Scene Helpers

extension MainSceneProducer {
    func makeWeeklyCalendarVC() -> UIViewController {
        guard let imageProvider = try? container.resolve(UIImageLoader.self) else {
            fatalError("WeeklyCalendarViewController dependencies not registered")
        }

        typealias WeeklyVM = WeeklyCalendarViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>,
            PhotoAuthorizationFetcher,
            PushNotificationObserver
        >

        guard let weeklyViewModel = try? container.resolve(WeeklyVM.self) else {
            fatalError("WeeklyCalendarViewModel not registered")
        }

        return WeeklyCalendarViewController(
            viewModel: weeklyViewModel,
            imageProvider: imageProvider,
            container: container
        )
    }

    func makeMonthlyCalendarVC() -> UIViewController {
        typealias MonthlyVM = MonthlyCalendarViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            PhotoAuthorizationFetcher
        >

        guard let monthlyViewModel = try? container.resolve(MonthlyVM.self) else {
            fatalError("MonthlyCalendarViewModel not registered")
        }

        return MonthlyCalendarViewController(
            viewModel: monthlyViewModel,
            container: container
        )
    }
}
