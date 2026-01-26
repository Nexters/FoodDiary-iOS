//
//  FoodEntity.swift
//  Domain
//
//  Created by 강대훈 on 1/12/26.
//

import Foundation

public struct LoginResult {
    public let isFirst: Bool
    
    public init(isFirst: Bool) {
        self.isFirst = isFirst
    }
}

extension LoginResult {
    public static let mock = LoginResult(isFirst: true)
}
