//
//  UserRepository.swift
//  Domain
//
//  Created by 강대훈 on 2/24/26.
//

import Foundation

public protocol UserRepository {
    func fetchProfile() async throws -> UserProfile
}
