//
//  AuthResponseDTO.swift
//  Data
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public struct AuthResponseDTO: Decodable {
    let accessToken: String
    let id: String
    let isFirst: Bool
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case id
        case isFirst = "is_first"
    }
}
