//
//  FoodClassificationResult.swift
//  Core
//
//  Created by Kai Lee on 1/18/26.
//

import Foundation

public enum FoodClassificationResult {
    case food(confidence: Float)
    case notFood(confidence: Float)
}
