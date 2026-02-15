//
//  PushTokenStorage.swift
//  Data
//
//  Created by 강대훈 on 2/15/26.
//

import Foundation
import Domain

/// UserDefaults를 사용한 푸시 토큰 저장소 구현체
public final class PushTokenStorage: PushTokenStoring {
    private let userDefaults: UserDefaults
    private let tokenKey = "push_token"

    /// 초기화
    /// - Parameter userDefaults: 토큰을 저장할 UserDefaults 인스턴스 (기본값: .standard)
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func get() -> String? {
        userDefaults.string(forKey: tokenKey)
    }

    public func set(_ token: String) {
        userDefaults.set(token, forKey: tokenKey)
    }

    public func clear() {
        userDefaults.removeObject(forKey: tokenKey)
    }
}
