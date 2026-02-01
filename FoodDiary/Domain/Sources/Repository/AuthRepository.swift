//
//  AuthRepository.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public protocol AuthRepository {
    func login(_ identityToken: Data) async throws -> LoginResult
    func logout() throws
}

