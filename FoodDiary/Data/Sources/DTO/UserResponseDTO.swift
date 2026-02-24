//
//  UserResponseDTO.swift
//  Data
//
//  Created by 강대훈 on 2/24/26.
//

import Domain
import Foundation

struct UserResponseDTO: Decodable {
    let name: String

    func toUserProfile() -> UserProfile {
        UserProfile(nickname: name)
    }
}
