//
//  DIContainerError.swift
//  DI
//
//  Created by 강대훈 on 1/25/26.
//

import Foundation

public enum DIContainerError: Error {
    case resolveFailure(service: String)
    
    public var description: String {
        switch self {
        case .resolveFailure(let key):
            "\(key)에 대한 Dependency Resolve 실패"
        }
    }
}
