//
//  InitialLaunchStoring.swift
//  Domain
//
//  Created by 강대훈 on 2/26/26.
//

import Foundation

public protocol InitialLaunchStoring: Sendable {
    func get() -> Bool
    func set()
}
