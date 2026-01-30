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

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let container = DIContainer.shared

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        registerDependencies()
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
        container.register(KeychainService.self) { _ in
            KeychainService()
        }
        
        container.register(HTTPClient<AuthEndpoint>.self) { _ in
            HTTPClient()
        }
        
        container.register(TokenManager<KeychainService>.self) { resolver in
            guard let service = resolver.resolve(KeychainService.self) else {
                fatalError("KeychainService not registered")
            }
            
            return TokenManager(keychainService: service)
        }
        
        container.register(AuthRepository.self) { resolver in
            guard let manager = resolver.resolve(TokenManager<KeychainService>.self) else {
                fatalError("TokenManager not registered")
            }
            
            guard let client = resolver.resolve(HTTPClient<AuthEndpoint>.self) else {
                fatalError("HTTPClient not registered")
            }
            
            return AuthRepositoryImpl(httpClient: client, tokenManager: manager)
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
    }
    
    func registerDomain() {
        container.register(FinalizeAppleLoginUseCase.self) { resolver in
            guard let repository = resolver.resolve(AuthRepository.self) else {
                fatalError("AuthRepository not registered")
            }
            
            return FinalizeAppleLoginUseCase(authRepository: repository)
        }

        container.register(FetchWeeklyCalendarUseCase<MockFoodRecordRepository>.self) { resolver in
            guard let repository = resolver.resolve(MockFoodRecordRepository.self) else {
                fatalError("MockFoodRecordRepository not registered")
            }
            return FetchWeeklyCalendarUseCase(repository: repository)
        }

        container.register(FetchFoodRecordsUseCase<MockFoodRecordRepository>.self) { resolver in
            guard let repository = resolver.resolve(MockFoodRecordRepository.self) else {
                fatalError("MockFoodRecordRepository not registered")
            }
            return FetchFoodRecordsUseCase(repository: repository)
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
    }
    
    func registerPresentation() {
        container.register(LoginViewModel.self, scope: .transient) { resolver in
            guard let useCase = resolver.resolve(FinalizeAppleLoginUseCase.self) else {
                fatalError("FinalizeAppleLoginUseCase not registered")
            }
            
            return LoginViewModel(finalizeAppleLoginUseCase: useCase)
        }
    }
}
