//
//  CoachmarkStoring.swift
//  Domain
//
//  Created by 강대훈 on 4/9/26.
//

import Foundation

public protocol CoachmarkStoring {
    func get() -> Bool
    func set()
}
