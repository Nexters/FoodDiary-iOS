//
//  LogoutUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation

public struct LogoutUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    /// 로그아웃을 수행합니다.
    ///
    /// AuthTokenStorage를 clear하여 저장된 액세스 토큰을 제거합니다.
    public func execute() throws {
        try authRepository.logout()
    }
}
