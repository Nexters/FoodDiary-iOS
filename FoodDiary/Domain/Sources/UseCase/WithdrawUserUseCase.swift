//
//  WithdrawUserUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation

public struct WithdrawUserUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    /// 회원탈퇴를 수행합니다.
    ///
    /// 서버에 회원탈퇴 요청을 전송하고, 로컬에 저장된 토큰을 삭제합니다.
    public func execute() async throws {
        try await authRepository.withdraw()
    }
}
