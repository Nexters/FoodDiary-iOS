//
//  VerificationResponseDTO.swift
//  Data
//
//  Created by 강대훈 on 2/10/26.
//

import Foundation

public struct ValidateResponseDTO: Decodable {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
