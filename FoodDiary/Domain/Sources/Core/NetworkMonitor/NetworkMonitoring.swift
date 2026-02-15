//
//  NetworkMonitoring.swift
//  Domain
//
//  Created by Claude on 2/13/26.
//

import Foundation
import Combine

/// 네트워크 연결 상태를 모니터링하는 프로토콜
public protocol NetworkMonitoring: Sendable {
    /// 현재 네트워크 연결 상태
    var isConnected: Bool { get }

    /// 네트워크 연결 상태 변경을 감지하는 Publisher
    var networkStatusPublisher: AnyPublisher<Bool, Never> { get }

    /// 네트워크 모니터링 시작
    func startMonitoring()

    /// 네트워크 모니터링 중지
    func stopMonitoring()
}
