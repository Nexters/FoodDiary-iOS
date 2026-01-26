//
//  LoginViewModelFactory.swift
//  Presentation
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation
import Domain

public struct LoginViewModelFactory {
    private let finalizeAppleLoginUseCase: FinalizeAppleLoginUseCase
    
    public init(finalizeAppleLoginUseCase: FinalizeAppleLoginUseCase) {
        self.finalizeAppleLoginUseCase = finalizeAppleLoginUseCase
    }
    
    public func make() -> LoginViewModel {
        return LoginViewModel(finalizeAppleLoginUseCase: finalizeAppleLoginUseCase)
    }
}

