//
//  TokenProviding.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

public protocol TokenManaging {
    func get() -> String?
    func set(_ token: String) throws
    func clear() throws
}

