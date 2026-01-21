//
//  FoodPhoto.swift
//  Data
//
//  Created by Kai Lee on 1/20/26.
//

import Photos
import UIKit

public struct FoodPhoto {
    public let asset: PHAsset
    /// 음식일 확률 (0.0 ~ 1.0)
    /// - food(0.9) -> 0.9
    /// - notFood(0.9) -> 0.1
    public let foodProbability: Float

    public init(asset: PHAsset, foodProbability: Float) {
        self.asset = asset
        self.foodProbability = foodProbability
    }
}
