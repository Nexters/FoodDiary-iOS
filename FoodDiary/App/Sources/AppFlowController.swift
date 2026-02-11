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
        guard let tokenManager = try? container.resolve(TokenManager<KeychainService>.self) else {
            fatalError("TokenManager Failed Resolve")
        }
        
        isLogin = tokenManager.get() != nil
    }
    
    func createMainView() -> UIViewController {
        guard let fetchFoodImageAssetUseCase = try? container.resolve(
            FetchFoodImageAssetUseCase<FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
        ) else {
            fatalError("FetchFoodImageAssetUseCase not registered")
        }

        guard let foodRecordRepository = try? container.resolve(MockFoodRecordRepository.self) else {
            fatalError("MockFoodRecordRepository not registered")
        }

        guard let imageProvider = try? container.resolve(UIImageLoader.self) else {
            fatalError("UIImageLoader not registered")
        }

        guard let requestPhotoAuthorizationUseCase = try? container.resolve(
            RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
        ) else {
            fatalError("RequestPhotoAuthorizationUseCase not registered")
        }

        guard let pendingRepository = try? container.resolve(PendingFoodRecordStorage.self) else {
            fatalError("PendingFoodRecordStorage not registered")
        }

        guard let analysisRepository = try? container.resolve(MockAnalysisResultRepository.self) else {
            fatalError("MockAnalysisResultRepository not registered")
        }

        let loadWeeklyCalendarDataUseCase = LoadWeeklyRecordUseCase(
            calendar: .current,
            recordRepository: foodRecordRepository,
            fetchFoodImageAssetUseCase: fetchFoodImageAssetUseCase
        )

        let saveFoodRecordUseCase = SaveFoodRecordUseCase(
            repository: foodRecordRepository,
            imageProvider: imageProvider,
            pendingRepository: pendingRepository
        )

        let restorePendingRecordsUseCase = RestorePendingRecordsUseCase(
            repository: pendingRepository
        )

        let checkPendingAnalysisUseCase = CheckPendingAnalysisUseCase(
            pendingRepository: pendingRepository,
            analysisRepository: analysisRepository
        )

        let pushNotificationObserver = PushNotificationObserver()

        let viewModel = WeeklyCalendarViewModel(
            requestPhotoAuthorizationUseCase: requestPhotoAuthorizationUseCase,
            loadWeeklyCalendarDataUseCase: loadWeeklyCalendarDataUseCase,
            saveFoodRecordUseCase: saveFoodRecordUseCase,
            restorePendingRecordsUseCase: restorePendingRecordsUseCase,
            checkPendingAnalysisUseCase: checkPendingAnalysisUseCase,
            pushNotificationObserver: pushNotificationObserver
        )
      
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

