//
//  InMemoryKeychainService.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

@testable import Data

final class InMemoryKeychainService: KeychainService {
    private var storage: [String: String] = [:]
    var shouldSaveSucceed: Bool = true
    
    override func save(key: String, value: String) -> Bool {
        guard shouldSaveSucceed else {
            return false
        }
        
        storage[key] = value
        return true
    }
    
    override func load(key: String) -> String? {
        storage[key]
    }
}
