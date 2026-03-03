//
//  FoodImageAsset.swift
//  Domain
//
//  Created by Kai Lee on 1/20/26.
//

import Foundation

public struct FoodImageAsset<ImageAsset: ImageAssetable>: Sendable, Equatable {
    public let imageAsset: ImageAsset
    /// 음식일 확률 (0.0 ~ 1.0)
    public let foodProbability: Float

    public var id: String { imageAsset.id }
    public var creationDate: Date? { imageAsset.creationDate }

    public init(imageAsset: ImageAsset, foodProbability: Float) {
        self.imageAsset = imageAsset
        self.foodProbability = foodProbability
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.foodProbability == rhs.foodProbability
    }
}
