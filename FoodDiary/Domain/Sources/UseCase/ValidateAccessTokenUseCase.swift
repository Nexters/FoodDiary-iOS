//
//  ValidateAccessTokenUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/10/26.
//

import Foundation

public struct ValidateAccessTokenUseCase<Repository: TokenRepository> {
    private let repository: Repository
    
    public init(repository: Repository) {
        self.repository = repository
    }
    
    public func execute() async -> Bool {
        await repository.verifyToken()
    }
}

