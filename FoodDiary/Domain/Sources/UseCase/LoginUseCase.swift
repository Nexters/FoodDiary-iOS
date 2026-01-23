//
//  LoginUseCase.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public struct LoginUseCase {
    private let loginRepository: LoginRepository
    
    public init(loginRepository: LoginRepository = LoginRepositoryImpl()) {
        self.loginRepository = loginRepository
    }
    
    public func execute(_ token: Data) async throws {
        try await loginRepository.sendIdentityToken(token)
    }
}
