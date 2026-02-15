//
//  PushTokenStoring.swift
//  Domain
//
//  Created by 강대훈 on 2/15/26.
//

import Foundation

/// 푸시 알림 토큰(FCM 등)을 저장하고 관리하는 프로토콜
public protocol PushTokenStoring: Sendable {
    /// 저장된 푸시 토큰을 가져옴
    /// - Returns: 푸시 토큰 문자열, 없을 경우 nil
    func get() -> String?

    /// 푸시 토큰을 저장
    /// - Parameter token: 저장할 푸시 토큰
    func set(_ token: String)

    /// 저장된 푸시 토큰을 삭제
    func clear()
}
