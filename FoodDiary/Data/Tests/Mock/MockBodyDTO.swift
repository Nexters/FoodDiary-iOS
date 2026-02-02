//
//  MockBodyDTO.swift
//  Core
//
//  Created by 강대훈 on 1/18/26.
//

import Foundation

struct MockBodyDTO: Encodable {
    let name: String
    let age: Int
}

struct MockResponseDTO: Codable, Equatable {
    let id: String
    let message: String
}
