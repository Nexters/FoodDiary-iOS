//
//  TokenProvider.swift
//  Data
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation
import Domain

public struct TokenManager: TokenManaging {
    let userDefault: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefault = userDefaults
    }
    
    public func get() -> String? {
        userDefault.string(forKey: "token")
    }
    
    public func set(_ token: String) {
        userDefault.set(token, forKey: "token")
    }
}
