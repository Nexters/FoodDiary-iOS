//
//  InitialLaunchStorage.swift
//  Data
//
//  Created by 강대훈 on 2/26/26.
//

import Domain
import Foundation

public struct InitialLaunchStorage: InitialLaunchStoring {
    private let key = "initial_launch"

    public init() {}

    public func get() -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    public func set() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
