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

        container.register(FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self) else {
                fatalError("FoodRecordRepositoryImpl dependencies not registered")
            }
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
            return FoodRecordRepositoryImpl(httpClient: client, tokenStorage: storage, deviceId: deviceId)
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

        container.register(PushNotificationObserver.self) { _ in
            PushNotificationObserver()
        }

        container.register(AddressSearchRepositoryImpl.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self) else {
                fatalError("AddressSearchRepositoryImpl dependencies not registered")
            }
            return AddressSearchRepositoryImpl(httpClient: client, tokenStorage: storage)
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
            DeletePendingRecordUseCase<PendingFoodRecordStorage<FileStorageService>>.self
        ) { resolver in
            guard let pendingRepo = resolver.resolve(PendingFoodRecordStorage<FileStorageService>.self) else {
                fatalError("PendingFoodRecordStorage not registered")
            }
            return DeletePendingRecordUseCase(repository: pendingRepo)
        }

        container.register(
            SaveFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>, UIImageLoader, PendingFoodRecordStorage<FileStorageService>>.self
        ) { resolver in
            guard let recordRepo = resolver.resolve(FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self),
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

        container.register(FetchMonthlyCalendarDaysUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return FetchMonthlyCalendarDaysUseCase(repository: repository)
        }

        container.register(
            FetchFoodRecordsUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
        ) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return FetchFoodRecordsUseCase(repository: repository)
        }

        container.register(
            LoadWeeklyRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>, FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
        ) { resolver in
            guard let recordRepo = resolver.resolve(FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self),
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

        container.register(
            UpdateFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
        ) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return UpdateFoodRecordUseCase(repository: repository)
        }

        container.register(
            DeleteFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
        ) { resolver in
            guard let repository = resolver.resolve(FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self) else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return DeleteFoodRecordUseCase(repository: repository)
        }

        container.register(
            SearchAddressUseCase<AddressSearchRepositoryImpl>.self
        ) { resolver in
            guard let addressRepo = resolver.resolve(AddressSearchRepositoryImpl.self) else {
                fatalError("AddressSearchRepositoryImpl not registered")
            }
            return SearchAddressUseCase(repository: addressRepo)
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
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>,
            PhotoAuthorizationFetcher,
            UIImageLoader,
            PendingFoodRecordStorage<FileStorageService>,
            PushNotificationObserver
        >

        container.register(WeeklyVM.self, scope: .transient) { resolver in
            guard let requestPhotoAuthUseCase = resolver.resolve(
                RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
            ),
                  let loadWeeklyUseCase = resolver.resolve(
                      LoadWeeklyRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>, FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>.self
                  ),
                  let saveFoodRecordUseCase = resolver.resolve(
                      SaveFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>, UIImageLoader, PendingFoodRecordStorage<FileStorageService>>.self
                  ),
                  let loadPendingUseCase = resolver.resolve(
                      LoadPendingRecordsUseCase<PendingFoodRecordStorage<FileStorageService>>.self
                  ),
                  let deletePendingUseCase = resolver.resolve(
                      DeletePendingRecordUseCase<PendingFoodRecordStorage<FileStorageService>>.self
                  ),
                  let pushObserver = resolver.resolve(PushNotificationObserver.self) else {
                fatalError("WeeklyCalendarViewModel dependencies not registered")
            }

            return WeeklyCalendarViewModel(
                requestPhotoAuthorizationUseCase: requestPhotoAuthUseCase,
                loadWeeklyCalendarDataUseCase: loadWeeklyUseCase,
                saveFoodRecordUseCase: saveFoodRecordUseCase,
                loadPendingRecordsUseCase: loadPendingUseCase,
                deletePendingRecordUseCase: deletePendingUseCase,
                pushNotificationObserver: pushObserver
            )
        }

        typealias DetailVM = DetailViewModel<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>

        container.register(
            DetailVM.self,
            argument: (Date, [FoodRecord]).self,
            scope: .transient,
            factory: { resolver, args in
                let (initialDate, initialRecords) = args
                guard let fetchRecordsUseCase = resolver.resolve(
                    FetchFoodRecordsUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
                ) else {
                    fatalError("FetchFoodRecordsUseCase not registered")
                }

                return DetailViewModel(
                    initialDate: initialDate,
                    initialRecords: initialRecords,
                    fetchRecordsUseCase: fetchRecordsUseCase
                )
            }
        )

        typealias EditVM = EditFoodRecordViewModel<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>

        container.register(
            EditVM.self,
            argument: FoodRecord.self,
            scope: .transient,
            factory: { resolver, record in
                guard let updateUseCase = resolver.resolve(
                    UpdateFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
                ),
                      let deleteUseCase = resolver.resolve(
                          DeleteFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
                      ) else {
                    fatalError("EditFoodRecordViewModel dependencies not registered")
                }

                return EditFoodRecordViewModel(
                    record: record,
                    updateFoodRecordUseCase: updateUseCase,
                    deleteFoodRecordUseCase: deleteUseCase
                )
            }
        )

        typealias AddressSearchVM = AddressSearchViewModel<AddressSearchRepositoryImpl>

        container.register(
            AddressSearchVM.self,
            argument: Int.self,
            scope: .transient,
            factory: { resolver, diaryId in
                guard let searchUseCase = resolver.resolve(
                    SearchAddressUseCase<AddressSearchRepositoryImpl>.self
                ) else {
                    fatalError("SearchAddressUseCase not registered")
                }
                return AddressSearchViewModel(
                    searchAddressUseCase: searchUseCase,
                    diaryId: diaryId
                )
            }
        )

        // MonthlyCalendarViewModel 타입 별칭
        typealias MonthlyVM = MonthlyCalendarViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            PhotoAuthorizationFetcher
        >

        container.register(MonthlyVM.self, scope: .transient) { resolver in
            guard let fetchMonthlyUseCase = resolver.resolve(
                FetchMonthlyCalendarDaysUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>.self
            ),
                  let requestPhotoAuthUseCase = resolver.resolve(
                      RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
                  ) else {
                fatalError("MonthlyCalendarViewModel dependencies not registered")
            }

            return MonthlyCalendarViewModel(
                fetchMonthlyCalendarDaysUseCase: fetchMonthlyUseCase,
                requestPhotoAuthorizationUseCase: requestPhotoAuthUseCase
            )
        }
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
