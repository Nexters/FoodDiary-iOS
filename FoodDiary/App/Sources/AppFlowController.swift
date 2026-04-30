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

    private var networkCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let container: DIContainer
    private let loginSession: LoginSession
    private var splashView: SplashView?
    private let coordinator: AppCoordinator
    private let transitionHandler: ViewTransitionHandling
    private let photoAuthFetcher: PhotoAuthorizationFetcher

    public init(
        appCoordinator: AppCoordinator,
        loginSession: LoginSession,
        container: DIContainer,
        transitionHandler: ViewTransitionHandling,
        photoAuthFetcher: PhotoAuthorizationFetcher
    ) {
        self.coordinator = appCoordinator
        self.loginSession = loginSession
        self.container = container
        self.transitionHandler = transitionHandler
        self.photoAuthFetcher = photoAuthFetcher
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
        setupForegroundReminderScheduling()
    }

    private func setupForegroundReminderScheduling() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tryScheduleDailyReminder()
            }
            .store(in: &cancellables)
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
                loginResult.isFirst ? showOnboarding() : pushMain()
            }
        }
    }

    private func showOnboarding() {
        let onboardingVC = OnboardingViewController()
        var cancellable: AnyCancellable?
        cancellable = onboardingVC.didCompletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                registerForRemoteNotificationsAfterLogin()
                pushMain()
                _ = cancellable
            }
        transition(to: UINavigationController(rootViewController: onboardingVC))
    }

    private func pushMain() {
        coordinator.pushMainVC()
        checkPhotoPermission()
    }

    private func checkPhotoPermission() {
        let status = photoAuthFetcher.authorizationStatus()
        guard status == .denied || status == .restricted else { return }
        coordinator.presentPermissionVC(from: self)
    }

    private func navigateToDetailFromDeepLink(diaryDateString: String) {
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
            pushMain()
            registerForRemoteNotificationsAfterLogin()
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
                tryScheduleDailyReminder()
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
            tryScheduleDailyReminder()
        } catch {
            print("알림 권한 요청 실패: \(error)")
        }
    }

    fileprivate func tryScheduleDailyReminder() {
        guard let useCase = try? container.resolve(ScheduleDailyReminderUseCase.self) else { return }
        Task { await useCase.execute() }
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
        transitionHandler.transition(from: self, to: viewController)
    }
}
