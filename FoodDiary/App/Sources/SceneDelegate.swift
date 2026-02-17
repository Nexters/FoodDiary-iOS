//
//  SceneDelegate.swift
//  App
//
//  Created by 강대훈 on 1/12/26.
//

import UIKit
import Data
import DesignSystem
import Presentation
import Domain
import DI
import Photos

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let container = DIContainer.shared

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        registerDependencies()
        #if DEBUG
        saveDebugImageToPhotoLibrary()
        #endif
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = AppFlowController(container: container)
        window?.makeKeyAndVisible()
    }

}

private extension SceneDelegate {
    func registerDependencies() {
        registerData()
        registerDomain()
        registerPresentation()
    }

    func registerData() {
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
        
        container.register(AuthTokenStorage<KeychainService>.self) { resolver in
            guard let service = resolver.resolve(KeychainService.self) else {
                fatalError("KeychainService not registered")
            }

            return AuthTokenStorage(keychainService: service)
        }
        
        container.register(AuthRepository.self) { resolver in
            guard let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self) else {
                fatalError("AuthTokenStorage not registered")
            }

            guard let client = resolver.resolve(HTTPClient.self) else {
                fatalError("HTTPClient not registered")
            }

            return AuthRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(TokenRepository.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self) else {
                fatalError("HTTPClient not registered")
            }

            guard let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self) else {
                fatalError("AuthTokenStorage not registered")
            }

            return TokenRepositoryImpl(httpClient: client, storage: storage)
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

        container.register(FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>.self) { resolver in
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

        container.register(MockFoodRecordRepository.self) { _ in
            MockFoodRecordRepository()
        }

        container.register(PhotoAuthorizationFetcher.self) { _ in
            PhotoAuthorizationFetcher()
        }

        container.register(FileStorageService.self) { _ in
            FileStorageService()
        }

        container.register(PendingFoodRecordStorage<FileStorageService>.self) { resolver in
            guard let fileStorage = resolver.resolve(FileStorageService.self) else {
                fatalError("FileStorageService not registered")
            }
            return PendingFoodRecordStorage(fileStorage: fileStorage)
        }

        container.register(MockAnalysisResultRepository.self) { _ in
            MockAnalysisResultRepository()
        }

        container.register(PushNotificationObserver.self) { _ in
            PushNotificationObserver()
        }
    }
    
    func registerDomain() {
        container.register(FinalizeAppleLoginUseCase.self) { resolver in
            guard let repository = resolver.resolve(AuthRepository.self),
                  let pushTokenStorage = resolver.resolve(PushTokenStoring.self),
                  let notificationAuthProvider = resolver.resolve(NotificationAuthorizationProviding.self),
                  let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
                fatalError("FinalizeAppleLoginUseCase dependencies not registered")
            }

            return FinalizeAppleLoginUseCase(
                authRepository: repository,
                deviceId: deviceId,
                osVersion: UIDevice.current.systemVersion,
                pushTokenStorage: pushTokenStorage,
                notificationAuthorizationProvider: notificationAuthProvider
            )
        }

        container.register(
            ValidateAccessTokenUseCase<TokenRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
        ) { resolver in
            guard let repository = resolver.resolve(TokenRepository.self) else {
                fatalError("TokenRepository not registered")
            }

            guard let concreteRepository = repository as? TokenRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>> else {
                fatalError("TokenRepository is not of expected type")
            }

            return ValidateAccessTokenUseCase(repository: concreteRepository)
        }

        container.register(
            FetchFoodImageAssetUseCase<FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
        ) { resolver in
            guard let repository = resolver.resolve(FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>.self) else {
                fatalError("FoodImageAssetFetcher not registered")
            }
            return FetchFoodImageAssetUseCase(repository: repository)
        }

        container.register(
            RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
        ) { resolver in
            guard let repository = resolver.resolve(PhotoAuthorizationFetcher.self) else {
                fatalError("PhotoAuthorizationFetcher not registered")
            }
            return RequestPhotoAuthorizationUseCase(repository: repository)
        }

        container.register(
            LoadPendingRecordsUseCase<PendingFoodRecordStorage<FileStorageService>>.self
        ) { resolver in
            guard let repository = resolver.resolve(PendingFoodRecordStorage<FileStorageService>.self) else {
                fatalError("PendingFoodRecordStorage not registered")
            }
            return LoadPendingRecordsUseCase(repository: repository)
        }

        container.register(
            SyncPendingAnalysisUseCase<PendingFoodRecordStorage<FileStorageService>, MockAnalysisResultRepository>.self
        ) { resolver in
            guard let pendingRepo = resolver.resolve(PendingFoodRecordStorage<FileStorageService>.self),
                  let analysisRepo = resolver.resolve(MockAnalysisResultRepository.self) else {
                fatalError("Pending analysis dependencies not registered")
            }
            return SyncPendingAnalysisUseCase(
                pendingRepository: pendingRepo,
                analysisRepository: analysisRepo
            )
        }

        container.register(
            SaveFoodRecordUseCase<MockFoodRecordRepository, UIImageLoader, PendingFoodRecordStorage<FileStorageService>>.self
        ) { resolver in
            guard let recordRepo = resolver.resolve(MockFoodRecordRepository.self),
                  let imageLoader = resolver.resolve(UIImageLoader.self),
                  let pendingRepo = resolver.resolve(PendingFoodRecordStorage<FileStorageService>.self) else {
                fatalError("SaveFoodRecordUseCase dependencies not registered")
            }
            return SaveFoodRecordUseCase(
                repository: recordRepo,
                imageProvider: imageLoader,
                pendingRepository: pendingRepo
            )
        }

        container.register(FetchMonthlyCalendarDaysUseCase<MockFoodRecordRepository>.self) { resolver in
            guard let repository = resolver.resolve(MockFoodRecordRepository.self) else {
                fatalError("MockFoodRecordRepository not registered")
            }
            return FetchMonthlyCalendarDaysUseCase(repository: repository)
        }

        container.register(
            FetchFoodRecordsUseCase<MockFoodRecordRepository>.self
        ) { resolver in
            guard let repository = resolver.resolve(MockFoodRecordRepository.self) else {
                fatalError("MockFoodRecordRepository not registered")
            }
            return FetchFoodRecordsUseCase(repository: repository)
        }

        container.register(
            LoadWeeklyRecordUseCase<MockFoodRecordRepository, FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
        ) { resolver in
            guard let recordRepo = resolver.resolve(MockFoodRecordRepository.self),
                  let fetchAssetUseCase = resolver.resolve(
                      FetchFoodImageAssetUseCase<FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
                  ) else {
                fatalError("LoadWeeklyRecordUseCase dependencies not registered")
            }
            return LoadWeeklyRecordUseCase(
                calendar: .current,
                recordRepository: recordRepo,
                fetchFoodImageAssetUseCase: fetchAssetUseCase
            )
        }

    }
    
    func registerPresentation() {
        container.register(LoginViewModel.self, scope: .transient) { resolver in
            guard let useCase = resolver.resolve(FinalizeAppleLoginUseCase.self) else {
                fatalError("FinalizeAppleLoginUseCase not registered")
            }

            return LoginViewModel(finalizeAppleLoginUseCase: useCase)
        }

        // WeeklyCalendarViewModel 타입 별칭
        typealias WeeklyVM = WeeklyCalendarViewModel<
            MockFoodRecordRepository,
            FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>,
            PhotoAuthorizationFetcher,
            UIImageLoader,
            PendingFoodRecordStorage<FileStorageService>,
            MockAnalysisResultRepository,
            PushNotificationObserver
        >

        container.register(WeeklyVM.self, scope: .transient) { resolver in
            guard let requestPhotoAuthUseCase = resolver.resolve(
                RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
            ),
                  let loadWeeklyUseCase = resolver.resolve(
                      LoadWeeklyRecordUseCase<MockFoodRecordRepository, FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
                  ),
                  let saveFoodRecordUseCase = resolver.resolve(
                      SaveFoodRecordUseCase<MockFoodRecordRepository, UIImageLoader, PendingFoodRecordStorage<FileStorageService>>.self
                  ),
                  let loadPendingUseCase = resolver.resolve(
                      LoadPendingRecordsUseCase<PendingFoodRecordStorage<FileStorageService>>.self
                  ),
                  let syncPendingUseCase = resolver.resolve(
                      SyncPendingAnalysisUseCase<PendingFoodRecordStorage<FileStorageService>, MockAnalysisResultRepository>.self
                  ),
                  let pushObserver = resolver.resolve(PushNotificationObserver.self),
                  let fetchFoodRecordsUseCase = resolver.resolve(
                      FetchFoodRecordsUseCase<MockFoodRecordRepository>.self
                  ) else {
                fatalError("WeeklyCalendarViewModel dependencies not registered")
            }

            return WeeklyCalendarViewModel(
                requestPhotoAuthorizationUseCase: requestPhotoAuthUseCase,
                loadWeeklyCalendarDataUseCase: loadWeeklyUseCase,
                saveFoodRecordUseCase: saveFoodRecordUseCase,
                loadPendingRecordsUseCase: loadPendingUseCase,
                syncPendingAnalysisUseCase: syncPendingUseCase,
                pushNotificationObserver: pushObserver,
                fetchFoodRecordsUseCase: fetchFoodRecordsUseCase
            )
        }

        typealias DetailVM = DetailViewModel<MockFoodRecordRepository>

        container.register(
            DetailVM.self,
            argument: Date.self,
            scope: .transient,
            factory: { resolver, initialDate in
                guard let fetchRecordsUseCase = resolver.resolve(
                    FetchFoodRecordsUseCase<MockFoodRecordRepository>.self
                ) else {
                    fatalError("FetchFoodRecordsUseCase not registered")
                }

                return DetailViewModel(
                    initialDate: initialDate,
                    fetchRecordsUseCase: fetchRecordsUseCase
                )
            }
        )
    }

    #if DEBUG
    func saveDebugImageToPhotoLibrary() {
        // PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        //     guard status == .authorized || status == .limited else { return }
    
        //     PHPhotoLibrary.shared().performChanges {
        //         guard let path = Bundle.main.path(forResource: "food", ofType: "jpg"),
        //               let image = UIImage(contentsOfFile: path) else { return }
        //         PHAssetChangeRequest.creationRequestForAsset(from: image)
        //     }
        // }
    }
    #endif
}
