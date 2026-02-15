//
//  DeviceInfoProviding.swift
//  Domain
//
//  Created by 강대훈 on 2/15/26.
//

import Foundation

/// 디바이스 정보를 제공하는 프로토콜
public protocol DeviceInfoProviding: Sendable {
    /// 디바이스 고유 식별자 (Vendor ID)
    /// - Returns: UUID 문자열, 없을 경우 nil
    var deviceId: String? { get }

    /// OS 버전
    /// - Returns: 시스템 버전 문자열 (예: "17.0")
    var osVersion: String { get }
}
