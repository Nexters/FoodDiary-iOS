//
//  FinalizeAppleLoginUseCase.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public struct FinalizeAppleLoginUseCase {
    private let tokenRepository: TokenRepository
    
    public init(tokenRepository: TokenRepository) {
        self.tokenRepository = tokenRepository
    }
    
    public func execute(_ token: Data) async throws -> LoginResult {
        return try await tokenRepository.save(token)
    }
}
