//
//  CoachmarkStorage.swift
//  Data
//
//  Created by 강대훈 on 4/9/26.
//

import Domain
import Foundation

public struct CoachmarkStorage: CoachmarkStoring {
    private let key = "has_shown_coachmark"

    public init() {}

    public func get() -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    public func set() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
