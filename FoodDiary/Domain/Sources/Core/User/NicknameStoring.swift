//
//  NicknameStoring.swift
//  Domain
//
//  Created by 강대훈 on 2/24/26.
//

import Foundation

public protocol NicknameStoring {
    func get() -> String?
    func set(_ nickname: String)
}
