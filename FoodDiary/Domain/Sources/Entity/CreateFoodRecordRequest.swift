//
//  CreateFoodRecordRequest.swift
//  Domain
//

import Foundation
import UIKit

/// 음식 기록 생성 요청 데이터
public struct CreateFoodRecordRequest: Sendable {
    public let date: Date
    public let images: [UIImage]

    public init(date: Date, images: [UIImage]) {
        self.date = date
        self.images = images
    }
}
