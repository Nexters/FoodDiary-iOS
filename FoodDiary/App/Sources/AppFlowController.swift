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
    private var isLogin: Bool = true
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
        updateLoginStateFromToken()
        routeToAppropriateScreen()
    }
}

private extension AppFlowController {
    func routeToAppropriateScreen() {
        let destinationVC = isLogin ? createMainView() : createLoginView()
        transition(to: destinationVC)
    }
    
    func updateLoginStateFromToken() {
        // TODO: 로그인 복구 시 아래 코드로 되돌릴 것
        // guard let tokenManager = try? container.resolve(TokenManager<KeychainService>.self) else {
        //     fatalError("TokenManager Failed Resolve")
        // }
        // isLogin = tokenManager.get() != nil
        isLogin = true
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

        let monthlyViewModel = MonthlyCalendarViewModel(
            fetchMonthlyCalendarDaysUseCase: fetchMonthlyCalendarDaysUseCase,
            requestPhotoAuthorizationUseCase: requestPhotoAuthorizationUseCase
        )

        let monthlyCalendarVC = MonthlyCalendarViewController(viewModel: monthlyViewModel)
        let weeklyCalendarVC = WeeklyCalendarViewController(viewModel: viewModel, imageProvider: imageProvider)

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
                guard let self else { return }
                self.isLogin = true
                self.routeToAppropriateScreen()
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

