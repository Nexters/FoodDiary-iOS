//
//  LoginSceneFactory.swift
//  Presentation
//

import Domain

public final class LoginSceneFactory {
    private let useCase: FinalizeAppleLoginUseCase

    public init(useCase: FinalizeAppleLoginUseCase) {
        self.useCase = useCase
    }

    public func makeScene() -> LoginViewController {
        LoginViewController(viewModel: LoginViewModel(finalizeAppleLoginUseCase: useCase))
    }
}
