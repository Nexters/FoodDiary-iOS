//
//  FinalizeAppleLoginUseCase.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public enum AppleLoginError: Error {
    case tokenPersistenceFailed
    case tokenDecodingFailed
}

public struct FinalizeAppleLoginUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute(_ token: Data) async throws -> LoginResult {
        return try await authRepository.login(token)
    }
}
