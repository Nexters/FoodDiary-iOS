//
//  CreateFoodRecordRequest.swift
//  Domain
//

import Foundation

/// 음식 기록 생성 요청 데이터
public struct CreateFoodRecordRequest: Sendable {
    public let date: Date
    public let assets: [any ImageAssetable]

    public init(date: Date, assets: [any ImageAssetable]) {
        self.date = date
        self.assets = assets
    }
}
