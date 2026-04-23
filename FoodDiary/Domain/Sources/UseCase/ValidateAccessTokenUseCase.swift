//
//  ValidateAccessTokenUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/10/26.
//

import Foundation

public struct ValidateAccessTokenUseCase {
    private let repository: any TokenRepository

    public init(repository: any TokenRepository) {
        self.repository = repository
    }
    
    /// 현재 저장된 액세스 토큰의 유효성을 검증합니다.
    ///
    /// 저장된 액세스 토큰을 조회한 뒤, 해당 토큰을 서버로 전달하여
    /// 유효성 검증을 요청합니다.
    /// 토큰이 존재하지 않거나, 검증 요청이 실패할 경우 `false`를 반환합니다.
    public func execute() async -> Bool {
        await repository.verifyToken()
    }
}

