//
//  GetNicknameUseCase.swift
//  Domain
//

import Foundation

public struct GetNicknameUseCase {
    private let nicknameStorage: NicknameStoring

    public init(nicknameStorage: NicknameStoring) {
        self.nicknameStorage = nicknameStorage
    }

    public func execute() -> String? {
        nicknameStorage.get()
    }
}
