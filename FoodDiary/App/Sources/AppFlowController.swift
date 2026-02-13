//
//  AppFlowController.swift
//  App
//
//  Created by 강대훈 on 1/23/26.
//

import Combine
import UIKit
import DI
import Presentation
import Domain
import Data

final class AppFlowController: UIViewController {
    private var currentChild: UIViewController?
    private var networkCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNetworkMonitoring()
    }
}

private extension AppFlowController {
    func setupNetworkMonitoring() {
        guard let networkMonitor = try? container.resolve(NetworkMonitoring.self) else {
            fatalError("NetworkMonitoring not registered")
        }

        networkMonitor.startMonitoring()
        
        networkCancellable = networkMonitor.networkStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.handleNetworkStatusChange(isConnected: isConnected)
            }
    }

    func handleNetworkStatusChange(isConnected: Bool) {
        if isConnected {
            proceedToNextScreen()
        }
    }

    func proceedToNextScreen() {
        Task {
            let isLogin = await validateToken()
            routeToAppropriateScreen(isLogin: isLogin)
            networkCancellable?.cancel()
            networkCancellable = nil
        }
    }

    func routeToAppropriateScreen(isLogin: Bool) {
        let destinationVC = isLogin ? createMainView() : createLoginView()
        transition(to: destinationVC)
    }
    
    func validateToken() async -> Bool {
        guard let validateAccessTokenUseCase = try? container.resolve(
            ValidateAccessTokenUseCase<TokenRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
        ) else {
            fatalError("ValidateAccessTokenUseCase Failed Resolve")
        }

        return await validateAccessTokenUseCase.execute()
    }
    
    func createMainView() -> UIViewController {
        guard let imageProvider = try? container.resolve(UIImageLoader.self) else {
            fatalError("UIImageLoader not registered")
        }

        typealias WeeklyVM = WeeklyCalendarViewModel<
            MockFoodRecordRepository,
            FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>,
            PhotoAuthorizationFetcher,
            UIImageLoader,
            PendingFoodRecordStorage<FileStorageService>,
            MockAnalysisResultRepository,
            PushNotificationObserver
        >

        guard let weeklyViewModel = try? container.resolve(WeeklyVM.self) else {
            fatalError("WeeklyCalendarViewModel not registered")
        }

        typealias DetailVM = DetailViewModel<MockFoodRecordRepository>

        let weeklyCalendarVC = WeeklyCalendarViewController(
            viewModel: weeklyViewModel,
            imageProvider: imageProvider,
            detailViewModelFactory: { [container] date in
                guard let vm = try? container.resolve(DetailVM.self, argument: date) else {
                    fatalError("DetailViewModel not registered")
                }
                return vm
            }
        )

        typealias MonthlyVM = MonthlyCalendarViewModel<
            MockFoodRecordRepository,
            PhotoAuthorizationFetcher
        >

        guard let monthlyViewModel = try? container.resolve(MonthlyVM.self) else {
            fatalError("MonthlyCalendarViewModel not registered")
        }

        let monthlyCalendarVC = MonthlyCalendarViewController(viewModel: monthlyViewModel)

        let tabBarVC = RootTabBarController(weeklyVC: weeklyCalendarVC, monthlyVC: monthlyCalendarVC, insightVC: UIViewController())
        return tabBarVC
    }
    
    func handleLoginResult(_ loginResult: LoginResult) {
        if loginResult.isFirst {
            transition(to: createOnboardingView())
        } else {
            transition(to: createMainView())
        }
    }

    func createOnboardingView() -> UIViewController {
        let onboardingVC = OnboardingViewController()

        onboardingVC.didCompletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                transition(to: createMainView())
            }
            .store(in: &cancellables)

        return UINavigationController(rootViewController: onboardingVC)
    }

    func createLoginView() -> UIViewController {
        guard let viewModel = try? container.resolve(LoginViewModel.self) else {
            fatalError("LoginViewModel Failed Resolve")
        }

        let loginVC = LoginViewController(viewModel: viewModel)

        loginVC.didLoginPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loginResult in
                guard let self else { return }
                handleLoginResult(loginResult)
            }
            .store(in: &cancellables)

        return loginVC
    }
    
    func transition(to viewController: UIViewController) {
        let previousChild = currentChild

        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.alpha = 0

        UIView.animate(
            withDuration: 0.3,
            animations: {
                previousChild?.view.alpha = 0
                viewController.view.alpha = 1
            },
            completion: { _ in
                previousChild?.willMove(toParent: nil)
                previousChild?.view.removeFromSuperview()
                previousChild?.removeFromParent()

                viewController.didMove(toParent: self)
                self.currentChild = viewController
            }
        )
    }
}

