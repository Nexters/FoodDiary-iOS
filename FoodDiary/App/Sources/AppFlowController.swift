//
//  AppFlowController.swift
//  App
//
//  Created by 강대훈 on 1/23/26.
//

import Combine
import DI
import Data
import Domain
import Presentation
import SnapKit
import UIKit
import UserNotifications

final class AppFlowController: UIViewController, SceneTransitioning {
    private typealias AssetFetcher = FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>
    private typealias FetchUseCase = FetchFoodImageAssetUseCase<AssetFetcher>

    private var currentChild: UIViewController?
    private var networkCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let container: DIContainer
    private let loginSession: LoginSession
    private var splashView: SplashView?
    private var pendingDeepLinkDate: String?

    private lazy var coordinator: AppCoordinator = {
        guard let sceneProducer = try? container.resolve(MainSceneProducer.self) else {
            fatalError("MainSceneProducer not registered")
        }
        let coordinator = AppCoordinator(
            container: container,
            sceneProducer: sceneProducer
        )
        coordinator.sceneTransitioner = self
        return coordinator
    }()

    public init(container: DIContainer) {
        guard let loginSession = try? container.resolve(LoginSession.self) else {
            fatalError("LoginSession not registered")
        }
        self.container = container
        self.loginSession = loginSession
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .sdBase
        setupSplashView()
        setupNetworkMonitoring()
        setupAnalysisCompletionToast()
        setupDeepLinkHandling()
        setupLoginSessionObservation()
    }

    private func setupLoginSessionObservation() {
        loginSession.loginResultPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loginResult in
                self?.handleLoginResult(loginResult)
            }
            .store(in: &cancellables)

        loginSession.logoutPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.coordinator.pushLoginVC()
            }
            .store(in: &cancellables)
    }

    private func setupSplashView() {
        let splash = SplashView()
        view.addSubview(splash)
        splash.snp.makeConstraints { $0.edges.equalToSuperview() }
        splashView = splash
    }

    private func setupAnalysisCompletionToast() {
        NotificationCenter.default.publisher(for: AppNotification.Push.analysisResult)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                ToastView.show(type: .imageUploadComplete)
            }
            .store(in: &cancellables)
    }

    private func setupDeepLinkHandling() {
        NotificationCenter.default.publisher(for: AppNotification.Push.deepLinkToDetail)
            .receive(on: DispatchQueue.main)
            .compactMap { $0.userInfo?[AppNotification.Push.Key.diaryDate] as? String }
            .sink { [weak self] diaryDateString in
                self?.navigateToDetailFromDeepLink(diaryDateString: diaryDateString)
            }
            .store(in: &cancellables)
    }

    fileprivate func handleLoginResult(_ loginResult: LoginResult) {
        Task { [weak self] in
            guard let self else { return }
            try? await fetchUserProfile()
            if !loginResult.isFirst {
                registerForRemoteNotificationsAfterLogin()
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                loginResult.isFirst ? showOnboarding() : coordinator.pushMainVC()
            }
        }
    }

    private func showOnboarding() {
        guard let sceneProducer = try? container.resolve(MainSceneProducer.self) else { return }
        let onboardingVC = sceneProducer.makeOnboardingScene()
        var cancellable: AnyCancellable?
        cancellable = onboardingVC.didCompletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                registerForRemoteNotificationsAfterLogin()
                coordinator.pushMainVC()
                _ = cancellable
            }
        transition(to: UINavigationController(rootViewController: onboardingVC))
    }

    private func navigateToDetailFromDeepLink(diaryDateString: String) {
        guard coordinator.currentNavigationController != nil else {
            pendingDeepLinkDate = diaryDateString
            return
        }
        coordinator.navigateToDetail(diaryDateString: diaryDateString)
    }
}

extension AppFlowController {
    fileprivate func setupNetworkMonitoring() {
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

    fileprivate func handleNetworkStatusChange(isConnected: Bool) {
        if isConnected {
            proceedToNextScreen()
        }
    }

    fileprivate func proceedToNextScreen() {
        Task {
            prefetchFoodImageAssets()

            async let minimumDelay: Void = Task.sleep(for: .seconds(1.5))
            async let loginResult = validateTokenAndFetchProfile()

            let (_, isLogin) = try await (minimumDelay, loginResult)

            await MainActor.run { [weak self] in
                guard let self else { return }
                routeToAppropriateScreen(isLogin: isLogin)
                networkCancellable?.cancel()
                networkCancellable = nil
            }
        }
    }

    private func removeSplashView() {
        splashView?.animateRemoval()
        splashView = nil
    }

    private func prefetchFoodImageAssets() {
        guard let useCase = try? container.resolve(FetchUseCase.self) else { return }
        useCase.prefetch(forPreviousWeeks: 2, of: Date())
    }

    private func validateTokenAndFetchProfile() async -> Bool {
        let isLogin = await validateToken()
        try? await fetchUserProfile()
        return isLogin
    }

    fileprivate func routeToAppropriateScreen(isLogin: Bool) {
        if isLogin {
            coordinator.pushMainVC()
            registerForRemoteNotificationsAfterLogin()
            if let deepLink = pendingDeepLinkDate {
                pendingDeepLinkDate = nil
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(0.5))
                    await MainActor.run { self?.coordinator.navigateToDetail(diaryDateString: deepLink) }
                }
            }
        } else {
            coordinator.pushLoginVC()
        }
        removeSplashView()
    }

    fileprivate func registerForRemoteNotificationsAfterLogin() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                UIApplication.shared.registerForRemoteNotifications()
            case .notDetermined:
                await requestSystemNotificationAuthorization()
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    @MainActor
    private func requestSystemNotificationAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            print("알림 권한 요청 실패: \(error)")
        }
    }

    fileprivate func validateToken() async -> Bool {
        guard
            let validateAccessTokenUseCase = try? container.resolve(
                ValidateAccessTokenUseCase<
                    TokenRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>, InitialLaunchStorage>
                >.self
            )
        else {
            fatalError("ValidateAccessTokenUseCase Failed Resolve")
        }

        return await validateAccessTokenUseCase.execute()
    }

    fileprivate func fetchUserProfile() async throws {
        guard
            let fetchUserProfileUseCase = try? container.resolve(
                FetchUserProfileUseCase<
                    UserRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                    NicknameStorage
                >.self
            )
        else {
            fatalError("FetchUserProfileUseCase Failed Resolve")
        }

        try await fetchUserProfileUseCase.execute()
    }

    func transition(to viewController: UIViewController) {
        let previousChild = currentChild

        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
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
