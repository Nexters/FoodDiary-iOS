//
//  DeviceInfoProvider.swift
//  Data
//
//  Created by 강대훈 on 2/15/26.
//

import UIKit
import Domain

/// UIDevice를 사용한 디바이스 정보 제공 구현체
public final class DeviceInfoProvider: DeviceInfoProviding {
    public init() {}

    public var deviceId: String? {
        UIDevice.current.identifierForVendor?.uuidString
    }

    public var osVersion: String {
        UIDevice.current.systemVersion
    }
}
