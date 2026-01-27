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
import Swinject

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
        container.register(TokenManager.self) { _ in
            TokenManager(userDefaults: .standard)
        }
        
        container.register(TokenRepository.self) { resolver in
            guard let manager = resolver.resolve(TokenManager.self) else {
                fatalError("TokenManager not registered")
            }
            return TokenRepositoryImpl(tokenManager: manager)
        }
    }
    
    func registerDomain() {
        container.register(FinalizeAppleLoginUseCase.self) { resolver in
            guard let repository = resolver.resolve(TokenRepository.self) else {
                fatalError("TokenRepository not registered")
            }
            return FinalizeAppleLoginUseCase(tokenRepository: repository)
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


