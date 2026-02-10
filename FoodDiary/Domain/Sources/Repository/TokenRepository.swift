//
//  TokenRepository.swift
//  Domain
//
//  Created by 강대훈 on 2/10/26.
//

import Foundation

public protocol TokenRepository {
    func verifyToken() async -> Bool
}
