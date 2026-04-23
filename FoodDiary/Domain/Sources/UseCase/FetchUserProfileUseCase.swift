//
//  FetchUserProfileUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/24/26.
//

import Foundation

public struct FetchUserProfileUseCase {
    private let repository: any UserRepository
    private let nicknameStorage: any NicknameStoring

    public init(repository: any UserRepository, nicknameStorage: any NicknameStoring) {
        self.repository = repository
        self.nicknameStorage = nicknameStorage
    }

    public func execute() async throws {
        let profile = try await repository.fetchProfile()
        nicknameStorage.set(profile.nickname)
    }
}
