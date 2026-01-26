//
//  FoodEntity.swift
//  Domain
//
//  Created by 강대훈 on 1/12/26.
//

import Foundation

public struct AuthResponse {
    let token: String
    let userID: String
    
    public init(token: String, userID: String) {
        self.token = token
        self.userID = userID
    }
}
