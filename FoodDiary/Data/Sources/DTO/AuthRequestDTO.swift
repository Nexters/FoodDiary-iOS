//
//  AuthRequestDTO.swift
//  Data
//
//  Created by 강대훈 on 1/26/26.
//

import Foundation
import Domain

public struct AuthRequestDTO: Encodable {
    let idToken: String
    let provider: SocialAuth

    public init(idToken: String, provider: SocialAuth) {
        self.idToken = idToken
        self.provider = provider
    }

    private enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case provider
    }
}
