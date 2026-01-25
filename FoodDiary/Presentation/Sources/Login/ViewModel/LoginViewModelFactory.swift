//
//  LoginViewModelFactory.swift
//  Presentation
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation
import Domain

public struct LoginViewModelFactory {
    private let loginUseCase: LoginUseCase
    
    public init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }
    
    public func make() -> LoginViewModel {
        return LoginViewModel(loginUseCase: loginUseCase)
    }
}

