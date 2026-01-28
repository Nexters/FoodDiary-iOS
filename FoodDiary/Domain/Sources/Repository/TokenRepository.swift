//
//  TokenRepository.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public protocol TokenRepository {
    func save(_ identityToken: Data) async throws -> LoginResult
    func deleteToken() throws
}
