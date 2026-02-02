//
//  CreateFoodRecordRequest.swift
//  Domain
//

import Foundation

/// 음식 기록 생성 요청 데이터
public struct CreateFoodRecordRequest: Sendable {
    public let date: Date
    public let localImageIdentifiers: [String]

    public init(date: Date, localImageIdentifiers: [String]) {
        self.date = date
        self.localImageIdentifiers = localImageIdentifiers
    }
}
