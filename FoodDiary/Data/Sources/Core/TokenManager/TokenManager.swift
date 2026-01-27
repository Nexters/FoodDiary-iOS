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
    
    public func getToken() -> String? {
        userDefault.string(forKey: "token")
    }
    
    public func setToken(_ token: String) {
        userDefault.set(token, forKey: "token")
    }
}
