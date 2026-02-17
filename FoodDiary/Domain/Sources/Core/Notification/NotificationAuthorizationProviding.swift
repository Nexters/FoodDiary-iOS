//
//  NotificationAuthorizationProviding.swift
//  Domain
//
//  Created by 강대훈 on 2/15/26.
//

import Foundation

/// 알림 권한 상태를 제공하는 프로토콜
public protocol NotificationAuthorizationProviding: Sendable {
    /// 현재 알림 권한 허용 여부를 확인
    /// - Returns: 알림이 허용되었으면 true, 아니면 false
    func isNotificationEnabled() async -> Bool
}
