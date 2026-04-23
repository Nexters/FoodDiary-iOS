//
//  SceneDelegate.swift
//  App
//
//  Created by 강대훈 on 1/12/26.
//

import DI
import Data
import DesignSystem
import Domain
import Photos
import Presentation
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let container = DIContainer.shared

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        registerDependencies()

        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        window?.rootViewController = makeAppFlowController()
        window?.makeKeyAndVisible()
    }
}

extension SceneDelegate {
    fileprivate func registerDependencies() {
        registerData()
        registerDomain()
        registerPresentation()
    }

    fileprivate func registerData() {
        container.register(NetworkMonitoring.self) { _ in
            NetworkMonitor()
        }

        container.register(PushTokenStoring.self) { _ in
            InMemoryPushTokenStorage()
        }

        container.register(NotificationAuthorizationProviding.self) { _ in
            NotificationAuthorizationProvider()
        }

        container.register(KeychainService.self) { _ in
            KeychainService()
        }

        container.register(HTTPClient.self) { _ in
            HTTPClient()
        }

        container.register(AuthTokenStorage.self) { resolver in
            guard let service = resolver.resolve(KeychainService.self) else {
                fatalError("KeychainService not registered")
            }
            return AuthTokenStorage(keychainService: service)
        }

        container.register(AuthRepository.self) { resolver in
            guard let storage = resolver.resolve(AuthTokenStorage.self),
                  let client = resolver.resolve(HTTPClient.self) else {
                fatalError("AuthRepositoryImpl dependencies not registered")
            }
            return AuthRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(TokenRepository.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage.self),
                  let launchStorage = resolver.resolve(InitialLaunchStorage.self) else {
                fatalError("TokenRepositoryImpl dependencies not registered")
            }
            return TokenRepositoryImpl(httpClient: client, storage: storage, launchStorage: launchStorage)
        }

        container.register(PHAssetConverter.self) { _ in
            PHAssetConverter()
        }

        container.register(UIImageLoader.self) { resolver in
            guard let imageLoader = resolver.resolve(PHAssetConverter.self) else {
                fatalError("PHImageLoader not registered")
            }
            return UIImageLoader(imageLoader: imageLoader)
        }

        container.register(TFLiteFoodClassifier.self) { _ in
            do {
                return try TFLiteFoodClassifier()
            } catch {
                fatalError("TFLiteFoodClassifier init failed: \(error)")
            }
        }

        container.register(ClassificationCacheManager.self) { _ in
            ClassificationCacheManager()
        }

        container.register(FoodImageAssetFetcher.self) { resolver in
            guard let classifier = resolver.resolve(TFLiteFoodClassifier.self),
                  let imageRepository = resolver.resolve(UIImageLoader.self),
                  let cache = resolver.resolve(ClassificationCacheManager.self) else {
                fatalError("FoodImageAssetFetcher dependencies not registered")
            }
            return FoodImageAssetFetcher(
                foodClassifier: classifier,
                imageRepository: imageRepository,
                cache: cache
            )
        }

        container.register(FoodRecordRepositoryImpl.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage.self),
                  let imageConverter = resolver.resolve(PHAssetConverter.self) else {
                fatalError("FoodRecordRepositoryImpl dependencies not registered")
            }
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
            return FoodRecordRepositoryImpl(
                httpClient: client, tokenStorage: storage, deviceId: deviceId,
                imageConverter: imageConverter)
        }

        container.register(PhotoAuthorizationFetcher.self) { _ in
            PhotoAuthorizationFetcher()
        }

        container.register(PushNotificationObserver.self) { _ in
            PushNotificationObserver()
        }

        container.register(AddressSearchRepositoryImpl.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage.self) else {
                fatalError("AddressSearchRepositoryImpl dependencies not registered")
            }
            return AddressSearchRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(DeviceRepository.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage.self) else {
                fatalError("DeviceRepository dependencies not registered")
            }
            return DeviceRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(UserRepository.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage.self) else {
                fatalError("UserRepositoryImpl dependencies not registered")
            }
            return UserRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(InsightRepositoryImpl.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage.self) else {
                fatalError("InsightRepositoryImpl dependencies not registered")
            }
            return InsightRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(NicknameStoring.self) { _ in
            NicknameStorage()
        }

        container.register(InitialLaunchStorage.self) { _ in
            InitialLaunchStorage()
        }

        container.register(CoachmarkStoring.self) { _ in
            CoachmarkStorage()
        }

        container.register(AnalysisCountStorage.self) { _ in
            AnalysisCountStorage()
        }
    }

    fileprivate func registerDomain() {
        container.register(LoginSession.self, scope: .container) { _ in
            LoginSession()
        }

        container.register(FinalizeAppleLoginUseCase.self) { resolver in
            guard let repository = resolver.resolve(AuthRepository.self),
                  let pushTokenStorage = resolver.resolve(PushTokenStoring.self),
                  let notificationAuthProvider = resolver.resolve(NotificationAuthorizationProviding.self),
                  let launchStorage = resolver.resolve(InitialLaunchStorage.self),
                  let loginSession = resolver.resolve(LoginSession.self),
                  let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
                fatalError("FinalizeAppleLoginUseCase dependencies not registered")
            }
            return FinalizeAppleLoginUseCase(
                authRepository: repository,
                deviceId: deviceId,
                osVersion: UIDevice.current.systemVersion,
                pushTokenStorage: pushTokenStorage,
                notificationAuthorizationProvider: notificationAuthProvider,
                initialLaunchStorage: launchStorage,
                loginSession: loginSession
            )
        }

        container.register(ValidateAccessTokenUseCase.self) { resolver in
            guard let repository = resolver.resolve(TokenRepository.self) else {
                fatalError("TokenRepository not registered")
            }
            return ValidateAccessTokenUseCase(repository: repository)
        }

        container.register(FetchFoodImageAssetUseCase.self) { resolver in
            guard let repository = resolver.resolve(FoodImageAssetFetcher.self) else {
                fatalError("FoodImageAssetFetcher not registered")
            }
            return FetchFoodImageAssetUseCase(repository: repository)
        }

        container.register(RequestPhotoAuthorizationUseCase.self) { resolver in
            guard let repository = resolver.resolve(PhotoAuthorizationFetcher.self) else {
                fatalError("PhotoAuthorizationFetcher not registered")
            }
            return RequestPhotoAuthorizationUseCase(repository: repository)
        }

        container.register(SaveFoodRecordUseCase.self) { resolver in
            guard let recordRepo = resolver.resolve(FoodRecordRepositoryImpl.self) else {
                fatalError("SaveFoodRecordUseCase dependencies not registered")
            }
            return SaveFoodRecordUseCase(repository: recordRepo)
        }

        container.register(FetchMonthlyCalendarDaysUseCase.self) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return FetchMonthlyCalendarDaysUseCase(repository: repository)
        }

        container.register(FetchFoodRecordsUseCase.self) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return FetchFoodRecordsUseCase(repository: repository)
        }

        container.register(LoadWeeklyRecordUseCase.self) { resolver in
            guard let recordRepo = resolver.resolve(FoodRecordRepositoryImpl.self),
                  let fetchAssetUseCase = resolver.resolve(FetchFoodImageAssetUseCase.self) else {
                fatalError("LoadWeeklyRecordUseCase dependencies not registered")
            }
            return LoadWeeklyRecordUseCase(
                calendar: .current,
                recordRepository: recordRepo,
                fetchFoodImageAssetUseCase: fetchAssetUseCase
            )
        }

        container.register(UpdateFoodRecordUseCase.self) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return UpdateFoodRecordUseCase(repository: repository)
        }

        container.register(DeleteFoodRecordUseCase.self) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return DeleteFoodRecordUseCase(repository: repository)
        }

        container.register(SearchAddressUseCase.self) { resolver in
            guard let addressRepo = resolver.resolve(AddressSearchRepositoryImpl.self) else {
                fatalError("AddressSearchRepositoryImpl not registered")
            }
            return SearchAddressUseCase(repository: addressRepo)
        }

        container.register(GetNicknameUseCase.self) { resolver in
            guard let nicknameStorage = resolver.resolve(NicknameStoring.self) else {
                fatalError("NicknameStoring not registered")
            }
            return GetNicknameUseCase(nicknameStorage: nicknameStorage)
        }

        container.register(CheckAppReviewEligibilityUseCase.self) { resolver in
            guard let storage = resolver.resolve(AnalysisCountStorage.self) else {
                fatalError("AnalysisCountStorage not registered")
            }
            return CheckAppReviewEligibilityUseCase(analysisCountStorage: storage)
        }

        container.register(GetAppVersionUseCase.self) { _ in
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            return GetAppVersionUseCase(appVersion: version)
        }

        container.register(LogoutUseCase.self) { resolver in
            guard let authRepository = resolver.resolve(AuthRepository.self),
                  let loginSession = resolver.resolve(LoginSession.self) else {
                fatalError("LogoutUseCase dependencies not registered")
            }
            return LogoutUseCase(authRepository: authRepository, loginSession: loginSession)
        }

        container.register(WithdrawUserUseCase.self) { resolver in
            guard let authRepository = resolver.resolve(AuthRepository.self),
                  let loginSession = resolver.resolve(LoginSession.self) else {
                fatalError("WithdrawUserUseCase dependencies not registered")
            }
            return WithdrawUserUseCase(authRepository: authRepository, loginSession: loginSession)
        }

        container.register(FetchInsightUseCase.self) { resolver in
            guard let repository = resolver.resolve(InsightRepositoryImpl.self) else {
                fatalError("FetchInsightUseCase dependencies not registered")
            }
            return FetchInsightUseCase(repository: repository)
        }

        container.register(FetchUserProfileUseCase.self) { resolver in
            guard let repository = resolver.resolve(UserRepository.self),
                  let nicknameStorage = resolver.resolve(NicknameStoring.self) else {
                fatalError("FetchUserProfileUseCase dependencies not registered")
            }
            return FetchUserProfileUseCase(repository: repository, nicknameStorage: nicknameStorage)
        }

        container.register(UpdateDeviceNotificationSettingUseCase.self) { resolver in
            guard let repository = resolver.resolve(DeviceRepository.self),
                  let pushTokenProvider = resolver.resolve(PushTokenStoring.self),
                  let notificationAuthProvider = resolver.resolve(NotificationAuthorizationProviding.self),
                  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                fatalError("UpdateDeviceNotificationSettingUseCase dependencies not registered")
            }
            let deviceID = UIDevice.current.identifierForVendor?.uuidString
            let osVersion = UIDevice.current.systemVersion
            return UpdateDeviceNotificationSettingUseCase(
                repository: repository,
                notificationAuthorizationProvider: notificationAuthProvider,
                pushTokenProvider: pushTokenProvider,
                appVersion: appVersion,
                deviceID: deviceID,
                osVersion: osVersion
            )
        }
    }

    fileprivate func registerPresentation() {}

    fileprivate func makeAppFlowController() -> AppFlowController {
        guard let finalizeUseCase = try? container.resolve(FinalizeAppleLoginUseCase.self) else {
            fatalError("FinalizeAppleLoginUseCase not registered")
        }

        guard let fetchInsightUseCase = try? container.resolve(FetchInsightUseCase.self) else {
            fatalError("FetchInsightUseCase not registered")
        }

        guard let updateDeviceUseCase = try? container.resolve(UpdateDeviceNotificationSettingUseCase.self),
              let notificationAuthProvider = try? container.resolve(NotificationAuthorizationProviding.self),
              let logoutUseCase = try? container.resolve(LogoutUseCase.self),
              let withdrawUserUseCase = try? container.resolve(WithdrawUserUseCase.self),
              let getNicknameUseCase = try? container.resolve(GetNicknameUseCase.self),
              let getAppVersionUseCase = try? container.resolve(GetAppVersionUseCase.self) else {
            fatalError("MyPageSceneFactory dependencies not registered")
        }

        guard let fetchImageAssetUseCase = try? container.resolve(FetchFoodImageAssetUseCase.self),
              let imageProvider = try? container.resolve(UIImageLoader.self) else {
            fatalError("ImagePickerCoordinator dependencies not registered")
        }

        let imagePickerFactory = ImagePickerSceneFactory(
            imageProvider: imageProvider,
            fetchUseCase: fetchImageAssetUseCase
        )

        guard let fetchRecordsUseCase = try? container.resolve(FetchFoodRecordsUseCase.self),
              let saveFoodRecordUseCase = try? container.resolve(SaveFoodRecordUseCase.self),
              let deleteFoodRecordUseCase = try? container.resolve(DeleteFoodRecordUseCase.self),
              let pushNotificationObserver = try? container.resolve(PushNotificationObserver.self) else {
            fatalError("DetailSceneFactory dependencies not registered")
        }

        guard let updateFoodRecordUseCase = try? container.resolve(UpdateFoodRecordUseCase.self) else {
            fatalError("EditSceneFactory dependencies not registered")
        }

        guard let searchAddressUseCase = try? container.resolve(SearchAddressUseCase.self) else {
            fatalError("AddressSearchSceneFactory dependencies not registered")
        }

        // Calendar
        guard
            let requestPhotoAuthUseCase = try? container.resolve(RequestPhotoAuthorizationUseCase.self),
            let loadWeeklyUseCase = try? container.resolve(LoadWeeklyRecordUseCase.self),
            let coachmarkStorage = try? container.resolve(CoachmarkStoring.self),
            let checkAppReviewUseCase = try? container.resolve(CheckAppReviewEligibilityUseCase.self),
            let fetchMonthlyUseCase = try? container.resolve(FetchMonthlyCalendarDaysUseCase.self)
        else {
            fatalError("CalendarSceneFactory dependencies not registered")
        }

        guard let photoAuthFetcher = try? container.resolve(PhotoAuthorizationFetcher.self) else {
            fatalError("PhotoAuthorizationFetcher not registered")
        }

        let factories = Factories(
            login: LoginSceneFactory(useCase: finalizeUseCase),
            calendar: CalendarSceneFactory(
                requestPhotoAuthorizationUseCase: requestPhotoAuthUseCase,
                loadWeeklyCalendarDataUseCase: loadWeeklyUseCase,
                saveFoodRecordUseCase: saveFoodRecordUseCase,
                pushNotificationObserver: pushNotificationObserver,
                getNicknameUseCase: getNicknameUseCase,
                coachmarkStorage: coachmarkStorage,
                checkAppReviewEligibilityUseCase: checkAppReviewUseCase,
                fetchMonthlyCalendarDaysUseCase: fetchMonthlyUseCase,
                fetchFoodRecordsUseCase: fetchRecordsUseCase
            ),
            insight: InsightSceneFactory(useCase: fetchInsightUseCase),
            myPage: MyPageSceneFactory(
                updateDeviceUseCase: updateDeviceUseCase,
                notificationAuthProvider: notificationAuthProvider,
                logoutUseCase: logoutUseCase,
                withdrawUserUseCase: withdrawUserUseCase,
                getNicknameUseCase: getNicknameUseCase,
                getAppVersionUseCase: getAppVersionUseCase
            ),
            detail: DetailSceneFactory(
                fetchRecordsUseCase: fetchRecordsUseCase,
                saveFoodRecordUseCase: saveFoodRecordUseCase,
                deleteFoodRecordUseCase: deleteFoodRecordUseCase,
                pushNotificationObserver: pushNotificationObserver
            ),
            imagePicker: imagePickerFactory,
            edit: EditSceneFactory(
                updateFoodRecordUseCase: updateFoodRecordUseCase,
                deleteFoodRecordUseCase: deleteFoodRecordUseCase
            ),
            addressSearch: AddressSearchSceneFactory(searchAddressUseCase: searchAddressUseCase),
            permission: PermissionSceneFactory()
        )

        guard let loginSession = try? container.resolve(LoginSession.self) else {
            fatalError("LoginSession not registered")
        }

        let appCoordinator = AppCoordinator(factories: factories)
        let transitionHandler = DefaultViewTransitionHandler()
        let appFlowController = AppFlowController(
            appCoordinator: appCoordinator,
            loginSession: loginSession,
            container: container,
            transitionHandler: transitionHandler,
            photoAuthFetcher: photoAuthFetcher
        )
        appCoordinator.sceneTransitioner = appFlowController
        return appFlowController
    }
}
