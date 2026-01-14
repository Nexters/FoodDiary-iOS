//
//  Modules.swift
//  Manifests
//
//  Created by 강대훈 on 1/12/26.
//

import Foundation

public enum Module {
    case app
    case core
    case data
    case designSystem
    case domain
    case feature(Feature)
}

public extension Module {
    enum Feature: String, CaseIterable {
        case main
        
        public var capitalized: String {
            rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }
}
