//
//  FetchUserProfileUseCase.swift
//  Domain
//
//  Created by 강대훈 on 2/24/26.
//

import Foundation

public struct FetchUserProfileUseCase<Repository: UserRepository, Storage: NicknameStoring> {
    private let repository: Repository
    private let nicknameStorage: Storage

    public init(repository: Repository, nicknameStorage: Storage) {
        self.repository = repository
        self.nicknameStorage = nicknameStorage
    }

    public func execute() async throws {
        let profile = try await repository.fetchProfile()
        nicknameStorage.set(profile.nickname)
    }
}
