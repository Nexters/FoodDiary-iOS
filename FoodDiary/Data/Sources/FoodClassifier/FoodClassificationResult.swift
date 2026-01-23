//
//  FoodClassificationResult.swift
//  Data
//
//  Created by Kai Lee on 1/18/26.
//

import Foundation

public enum FoodClassificationResult {
    case food(confidence: Float)
    case notFood(confidence: Float)

    var foodProbability: Float {
        switch self {
        case .food(let confidence):
            return confidence
        case .notFood(let confidence):
            return 1.0 - confidence
        }
    }
}
