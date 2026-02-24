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

        #if DEBUG
            // saveDebugImageToPhotoLibrary()
        #endif
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = AppFlowController(container: container)
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

        container.register(FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>.self) {
            resolver in
            guard let classifier = resolver.resolve(TFLiteFoodClassifier.self),
                let imageRepository = resolver.resolve(UIImageLoader.self),
                let cache = resolver.resolve(ClassificationCacheManager.self)
            else {
                fatalError("FoodImageAssetFetcher dependencies not registered")
            }
            return FoodImageAssetFetcher(
                foodClassifier: classifier,
                imageRepository: imageRepository,
                cache: cache
            )
        }

        container.register(
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self
        ) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self),
                let imageConverter = resolver.resolve(PHAssetConverter.self)
            else {
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
                let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self)
            else {
                fatalError("AddressSearchRepositoryImpl dependencies not registered")
            }
            return AddressSearchRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(DeviceRepository.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self) else {
                fatalError("DeviceRepository dependencies not registered")
            }
            return DeviceRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(UserRepository.self) { resolver in
            guard let client = resolver.resolve(HTTPClient.self),
                  let storage = resolver.resolve(AuthTokenStorage<KeychainService>.self) else {
                fatalError("UserRepositoryImpl dependencies not registered")
            }
            return UserRepositoryImpl(httpClient: client, tokenStorage: storage)
        }

        container.register(NicknameStoring.self) { _ in
            NicknameStorage()
        }
    }

    fileprivate func registerDomain() {
        container.register(FinalizeAppleLoginUseCase.self) { resolver in
            guard let repository = resolver.resolve(AuthRepository.self),
                let pushTokenStorage = resolver.resolve(PushTokenStoring.self),
                let notificationAuthProvider = resolver.resolve(
                    NotificationAuthorizationProviding.self),
                let deviceId = UIDevice.current.identifierForVendor?.uuidString
            else {
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
            ValidateAccessTokenUseCase<
                TokenRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
            >.self
        ) { resolver in
            guard let repository = resolver.resolve(TokenRepository.self) else {
                fatalError("TokenRepository not registered")
            }

            guard
                let concreteRepository = repository
                    as? TokenRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
            else {
                fatalError("TokenRepository is not of expected type")
            }

            return ValidateAccessTokenUseCase(repository: concreteRepository)
        }

        container.register(
            FetchFoodImageAssetUseCase<FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>>
                .self
        ) { resolver in
            guard
                let repository = resolver.resolve(
                    FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>.self)
            else {
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
            guard
                let repository = resolver.resolve(PendingFoodRecordStorage<FileStorageService>.self)
            else {
                fatalError("PendingFoodRecordStorage not registered")
            }
            return LoadPendingRecordsUseCase(repository: repository)
        }

        container.register(
            DeletePendingRecordUseCase<PendingFoodRecordStorage<FileStorageService>>.self
        ) { resolver in
            guard
                let pendingRepo = resolver.resolve(
                    PendingFoodRecordStorage<FileStorageService>.self)
            else {
                fatalError("PendingFoodRecordStorage not registered")
            }
            return DeletePendingRecordUseCase(repository: pendingRepo)
        }

        container.register(
            SaveFoodRecordUseCase<
                FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                PendingFoodRecordStorage<FileStorageService>
            >.self
        ) { resolver in
            guard
                let recordRepo = resolver.resolve(
                    FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self),
                let pendingRepo = resolver.resolve(
                    PendingFoodRecordStorage<FileStorageService>.self)
            else {
                fatalError("SaveFoodRecordUseCase dependencies not registered")
            }
            return SaveFoodRecordUseCase(
                repository: recordRepo,
                pendingRepository: pendingRepo
            )
        }

        container.register(
            FetchMonthlyCalendarDaysUseCase<
                FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
            >.self
        ) { resolver in
            guard
                let repository = resolver.resolve(
                    FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self)
            else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return FetchMonthlyCalendarDaysUseCase(repository: repository)
        }

        container.register(
            FetchFoodRecordsUseCase<
                FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
            >.self
        ) { resolver in
            guard
                let repository = resolver.resolve(
                    FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self)
            else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return FetchFoodRecordsUseCase(repository: repository)
        }

        container.register(
            LoadWeeklyRecordUseCase<
                FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>
            >.self
        ) { resolver in
            guard
                let recordRepo = resolver.resolve(
                    FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self),
                let fetchAssetUseCase = resolver.resolve(
                    FetchFoodImageAssetUseCase<
                        FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>
                    >.self
                )
            else {
                fatalError("LoadWeeklyRecordUseCase dependencies not registered")
            }
            return LoadWeeklyRecordUseCase(
                calendar: .current,
                recordRepository: recordRepo,
                fetchFoodImageAssetUseCase: fetchAssetUseCase
            )
        }

        container.register(
            UpdateFoodRecordUseCase<
                FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
            >.self
        ) { resolver in
            guard
                let repository = resolver.resolve(
                    FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self)
            else {
                fatalError("FoodRecordRepositoryImpl not registered")
            }
            return UpdateFoodRecordUseCase(repository: repository)
        }

        container.register(
            DeleteFoodRecordUseCase<
                FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
            >.self
        ) { resolver in
            guard
                let repository = resolver.resolve(
                    FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>.self)
            else {
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

        container.register(GetNicknameUseCase.self) { resolver in
            guard let nicknameStorage = resolver.resolve(NicknameStoring.self) else {
                fatalError("NicknameStoring not registered")
            }
            return GetNicknameUseCase(nicknameStorage: nicknameStorage)
        }

        container.register(LogoutUseCase.self) { resolver in
            guard let authRepository = resolver.resolve(AuthRepository.self) else {
                fatalError("AuthRepository not registered")
            }
            return LogoutUseCase(authRepository: authRepository)
        }

        container.register(WithdrawUserUseCase.self) { resolver in
            guard let authRepository = resolver.resolve(AuthRepository.self) else {
                fatalError("AuthRepository not registered")
            }
            return WithdrawUserUseCase(authRepository: authRepository)
        }

        container.register(
            FetchUserProfileUseCase<
                UserRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                NicknameStorage
            >.self
        ) { resolver in
            guard let repository = resolver.resolve(UserRepository.self),
                  let concreteRepository = repository
                      as? UserRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                  let nicknameStorage = resolver.resolve(NicknameStoring.self),
                  let concreteNicknameStorage = nicknameStorage as? NicknameStorage
            else {
                fatalError("FetchUserProfileUseCase dependencies not registered or unexpected type")
            }
            return FetchUserProfileUseCase(
                repository: concreteRepository,
                nicknameStorage: concreteNicknameStorage
            )
        }

        container.register(
            UpdateDeviceNotificationSettingUseCase.self
        ) { resolver in
            guard let repository = resolver.resolve(DeviceRepository.self),
                  let pushTokenProvider = resolver.resolve(PushTokenStoring.self),
                  let notificationAuthProvider = resolver.resolve(NotificationAuthorizationProviding.self),
                  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                fatalError("UpdateDeviceNotificationSettingUseCase dependencies not registered")
            }

            guard let concreteRepository = repository as? DeviceRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>> else {
                fatalError("DeviceRepository is not of expected type")
            }

            let deviceID = UIDevice.current.identifierForVendor?.uuidString
            let osVersion = UIDevice.current.systemVersion

            return UpdateDeviceNotificationSettingUseCase(
                repository: concreteRepository,
                notificationAuthorizationProvider: notificationAuthProvider,
                pushTokenProvider: pushTokenProvider,
                appVersion: appVersion,
                deviceID: deviceID,
                osVersion: osVersion
            )
        }
    }

    fileprivate func registerPresentation() {
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
            PendingFoodRecordStorage<FileStorageService>,
            PushNotificationObserver
        >

        container.register(WeeklyVM.self, scope: .transient) { resolver in
            guard
                let requestPhotoAuthUseCase = resolver.resolve(
                    RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
                ),
                let loadWeeklyUseCase = resolver.resolve(
                    LoadWeeklyRecordUseCase<
                        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                        FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>
                    >.self
                ),
                let saveFoodRecordUseCase = resolver.resolve(
                    SaveFoodRecordUseCase<
                        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                        PendingFoodRecordStorage<FileStorageService>
                    >.self
                ),
                let loadPendingUseCase = resolver.resolve(
                    LoadPendingRecordsUseCase<PendingFoodRecordStorage<FileStorageService>>.self
                ),
                let deletePendingUseCase = resolver.resolve(
                    DeletePendingRecordUseCase<PendingFoodRecordStorage<FileStorageService>>.self
                ),
                let pushObserver = resolver.resolve(PushNotificationObserver.self)
            else {
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

        typealias DetailVM = DetailViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            PendingFoodRecordStorage<FileStorageService>,
            PushNotificationObserver
        >

        container.register(
            DetailVM.self,
            argument: (Date, [FoodRecord]).self,
            scope: .transient,
            factory: { resolver, args in
                let (initialDate, initialRecords) = args
                guard
                    let fetchRecordsUseCase = resolver.resolve(
                        FetchFoodRecordsUseCase<
                            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
                        >.self
                    ),
                    let saveFoodRecordUseCase = resolver.resolve(
                        SaveFoodRecordUseCase<
                            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
                            PendingFoodRecordStorage<FileStorageService>
                        >.self
                    ),
                    let loadPendingUseCase = resolver.resolve(
                        LoadPendingRecordsUseCase<PendingFoodRecordStorage<FileStorageService>>.self
                    ),
                    let deletePendingUseCase = resolver.resolve(
                        DeletePendingRecordUseCase<PendingFoodRecordStorage<FileStorageService>>.self
                    ),
                    let pushObserver = resolver.resolve(PushNotificationObserver.self)
                else {
                    fatalError("DetailViewModel dependencies not registered")
                }

                return DetailViewModel(
                    initialDate: initialDate,
                    initialRecords: initialRecords,
                    fetchRecordsUseCase: fetchRecordsUseCase,
                    saveFoodRecordUseCase: saveFoodRecordUseCase,
                    loadPendingRecordsUseCase: loadPendingUseCase,
                    deletePendingRecordUseCase: deletePendingUseCase,
                    pushNotificationObserver: pushObserver
                )
            }
        )

        typealias EditVM = EditFoodRecordViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
        >

        container.register(
            EditVM.self,
            argument: FoodRecord.self,
            scope: .transient,
            factory: { resolver, record in
                guard
                    let updateUseCase = resolver.resolve(
                        UpdateFoodRecordUseCase<
                            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
                        >.self
                    ),
                    let deleteUseCase = resolver.resolve(
                        DeleteFoodRecordUseCase<
                            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
                        >.self
                    )
                else {
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
                guard
                    let searchUseCase = resolver.resolve(
                        SearchAddressUseCase<AddressSearchRepositoryImpl>.self
                    )
                else {
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
            guard
                let fetchMonthlyUseCase = resolver.resolve(
                    FetchMonthlyCalendarDaysUseCase<
                        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
                    >.self
                ),
                let requestPhotoAuthUseCase = resolver.resolve(
                    RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>.self
                ),
                let fetchFoodRecordsUseCase = resolver.resolve(
                    FetchFoodRecordsUseCase<
                        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
                    >.self
                ),
                let getNicknameUseCase = resolver.resolve(GetNicknameUseCase.self)
            else {
                fatalError("MonthlyCalendarViewModel dependencies not registered")
            }

            return MonthlyCalendarViewModel(
                fetchMonthlyCalendarDaysUseCase: fetchMonthlyUseCase,
                requestPhotoAuthorizationUseCase: requestPhotoAuthUseCase,
                fetchFoodRecordsUseCase: fetchFoodRecordsUseCase,
                getNicknameUseCase: getNicknameUseCase
            )
        }

        container.register(MyPageViewModel.self, scope: .transient) { resolver in
            guard let updateDeviceUseCase = resolver.resolve(
                UpdateDeviceNotificationSettingUseCase.self
            ),
                  let notificationAuthProvider = resolver.resolve(NotificationAuthorizationProviding.self),
                  let logoutUseCase = resolver.resolve(LogoutUseCase.self),
                  let withdrawUserUseCase = resolver.resolve(WithdrawUserUseCase.self),
                  let getNicknameUseCase = resolver.resolve(GetNicknameUseCase.self) else {
                fatalError("MyPageViewModel dependencies not registered")
            }

            return MyPageViewModel(
                updateDeviceNotificationSettingUseCase: updateDeviceUseCase,
                notificationAuthorizationProvider: notificationAuthProvider,
                logoutUseCase: logoutUseCase,
                withdrawUserUseCase: withdrawUserUseCase,
                getNicknameUseCase: getNicknameUseCase
            )
        }
    }

    #if DEBUG
        fileprivate func saveDebugImageToPhotoLibrary() {
            // PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            //     guard status == .authorized || status == .limited else { return }

            //     guard let path = Bundle.main.path(forResource: "food", ofType: "jpg"),
            //         let image = UIImage(contentsOfFile: path)
            //     else { return }

            //     let calendar = Calendar.current
            //     let today = calendar.startOfDay(for: Date())

            //     for dayOffset in 0..<7 {
            //         guard
            //             let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)
            //         else { continue }
            //         PHPhotoLibrary.shared().performChanges {
            //             let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            //             request.creationDate = targetDate
            //         }
            //     }
            // }
        }
    #endif
}
