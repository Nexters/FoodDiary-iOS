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
        
        networkMonitor.networkStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.handleNetworkStatusChange(isConnected: isConnected)
            }
            .store(in: &cancellables)
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
            cancellables.removeAll()
        }
    }

    func routeToAppropriateScreen(isLogin: Bool) {
        let destinationVC = isLogin ? createMainView() : createLoginView()
        transition(to: destinationVC)
    }
    
    func validateToken() async -> Bool {
        guard let validateAccessTokenUseCase = try? container.resolve(
            ValidateAccessTokenUseCase<TokenRepositoryImpl<HTTPClient, TokenManager<KeychainService>>>.self
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

        guard let viewModel = try? container.resolve(WeeklyVM.self) else {
            fatalError("WeeklyCalendarViewModel not registered")
        }

        guard let requestPhotoAuthorizationUseCase = try? container.resolve(
            RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
        ) else {
            fatalError("RequestPhotoAuthorizationUseCase not registered")
        }

        guard let fetchMonthlyCalendarDaysUseCase = try? container.resolve(
            FetchMonthlyCalendarDaysUseCase<MockFoodRecordRepository>.self
        ) else {
            fatalError("FetchMonthlyCalendarDaysUseCase not registered")
        }

        typealias DetailVM = DetailViewModel<MockFoodRecordRepository>

        let weeklyCalendarVC = WeeklyCalendarViewController(
            viewModel: viewModel,
            imageProvider: imageProvider,
            detailViewModelFactory: { [container] date in
                guard let vm = try? container.resolve(DetailVM.self, argument: date) else {
                    fatalError("DetailViewModel not registered")
                }
                return vm
            }
        )

        return UINavigationController(rootViewController: weeklyCalendarVC)
    }
    
    func createLoginView() -> UIViewController {
        guard let viewModel = try? container.resolve(LoginViewModel.self) else {
            fatalError("LoginViewModel Failed Resolve")
        }
        
        let loginVC = LoginViewController(viewModel: viewModel)
        
        loginVC.didLoginPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.routeToAppropriateScreen(isLogin: true)
            }
            .store(in: &cancellables)

        return loginVC
    }
    
    func transition(to viewController: UIViewController) {
        if let currentChild {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }

        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)

        currentChild = viewController
    }
}

