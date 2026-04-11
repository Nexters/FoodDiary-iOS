//
//  LogoutUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation

public struct LogoutUseCase {
    private let authRepository: AuthRepository
    private let loginSession: LoginSession

    public init(authRepository: AuthRepository, loginSession: LoginSession) {
        self.authRepository = authRepository
        self.loginSession = loginSession
    }

    /// 로그아웃을 수행합니다.
    ///
    /// AuthTokenStorage를 clear하여 저장된 액세스 토큰을 제거하고,
    /// LoginSession을 통해 로그아웃 이벤트를 전달합니다.
    public func execute() throws {
        try authRepository.logout()
        loginSession.notifyLogout()
    }
}
