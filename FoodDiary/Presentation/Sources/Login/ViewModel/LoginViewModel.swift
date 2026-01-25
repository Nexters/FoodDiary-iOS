//
//  LoginViewModel.swift
//  Presentation
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation
import Domain

final public class LoginViewModel {
    private let loginUseCase: LoginUseCase = LoginUseCase()
    
    public init() {}
    
    public func sendIdentityToken(_ token: Data) async throws {
        try await loginUseCase.execute(token)
    }
}
