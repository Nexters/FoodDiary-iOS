//
//  DeviceRepository.swift
//  Domain
//
//  Created by 강대훈 on 2/20/26.
//

import Foundation

public protocol DeviceRepository {
    func updateNotificationSetting(_ request: UpdateDeviceNotificationRequest) async throws
}
