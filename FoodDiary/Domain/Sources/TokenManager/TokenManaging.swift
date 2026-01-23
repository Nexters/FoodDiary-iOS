//
//  TokenProviding.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public protocol TokenManaging {
    func getToken() -> String?
    func setToken(_ token: String)
}

// TODO: Data로 이동
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
