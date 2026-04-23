//
//  KeychainServicing.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

import Foundation

public protocol KeychainServicing: Sendable {
    func save(key: String, value: String) -> Bool
    func load(key: String) -> String?
    func delete(key: String) -> Bool
}

