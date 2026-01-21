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
    public let confidenceScore: Float

    public init(asset: PHAsset, confidenceScore: Float) {
        self.asset = asset
        self.confidenceScore = confidenceScore
    }
}
