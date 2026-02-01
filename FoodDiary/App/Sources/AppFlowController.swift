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
        routeToAppropriateScreen()
    }
}

private extension AppFlowController {
    func routeToAppropriateScreen() {
        let destinationVC = isLogin ? createMainView() : createLoginView()
        transition(to: destinationVC)
    }
    
    func createMainView() -> UIViewController {
        guard let weeklyCalendarUseCase = try? container.resolve(
            FetchWeeklyCalendarUseCase<MockFoodRecordRepository>.self
        ) else {
            fatalError("FetchWeeklyCalendarUseCase not registered")
        }

        guard let fetchFoodImageAssetUseCase = try? container.resolve(
            FetchFoodImageAssetUseCase<FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
        ) else {
            fatalError("FetchFoodImageAssetUseCase not registered")
        }

        guard let fetchFoodRecordsUseCase = try? container.resolve(
            FetchFoodRecordsUseCase<MockFoodRecordRepository>.self
        ) else {
            fatalError("FetchFoodRecordsUseCase not registered")
        }

        guard let imageProvider = try? container.resolve(UIImageLoader.self) else {
            fatalError("UIImageLoader not registered")
        }

        guard let requestPhotoAuthorizationUseCase = try? container.resolve(
            RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
        ) else {
            fatalError("RequestPhotoAuthorizationUseCase not registered")
        }

        let viewModel = WeeklyCalendarViewModel(
            fetchWeeklyCalendarUseCase: weeklyCalendarUseCase,
            fetchFoodImageAssetUseCase: fetchFoodImageAssetUseCase,
            fetchFoodRecordsUseCase: fetchFoodRecordsUseCase,
            requestPhotoAuthorizationUseCase: requestPhotoAuthorizationUseCase
        )

        let weeklyCalendarVC = WeeklyCalendarViewController(
            viewModel: viewModel,
            imageProvider: imageProvider
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
                self?.handleLoginSuccess()
            }
            .store(in: &cancellables)
       
        return loginVC
    }
    
    func handleLoginSuccess() {
        isLogin = true
        routeToAppropriateScreen()
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
