//
//  GetAppVersionUseCase.swift
//  Domain
//

import Foundation

public struct GetAppVersionUseCase {
    private let appVersion: String

    public init(appVersion: String) {
        self.appVersion = appVersion
    }

    public func execute() -> String {
        return appVersion
    }
}
