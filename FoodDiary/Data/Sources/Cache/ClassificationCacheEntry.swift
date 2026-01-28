//
//  ClassificationCacheEntry.swift
//  Data
//
//  Created by Kai Lee on 1/25/26.
//

public struct ClassificationCacheEntry: Codable, Sendable {
    public let assetIdentifier: String
    public let foodProbability: Float

    public init(identifier: String, foodProbability: Float) {
        self.assetIdentifier = identifier
        self.foodProbability = foodProbability
    }
}
