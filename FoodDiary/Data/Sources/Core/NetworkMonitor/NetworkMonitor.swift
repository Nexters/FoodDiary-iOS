//
//  NetworkMonitor.swift
//  Data
//
//  Created by 강대훈 on 2/13/26.
//

import Foundation
import Network
import Combine
import Domain

public final class NetworkMonitor: NetworkMonitoring {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let statusSubject = CurrentValueSubject<Bool, Never>(false)

    public var isConnected: Bool {
        statusSubject.value
    }

    public var networkStatusPublisher: AnyPublisher<Bool, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    public init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.fooddiary.networkmonitor")
        setupMonitor()
    }

    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.statusSubject.send(isConnected)
        }
    }

    public func startMonitoring() {
        monitor.start(queue: queue)
    }

    public func stopMonitoring() {
        monitor.cancel()
    }

    deinit {
        stopMonitoring()
    }
}
