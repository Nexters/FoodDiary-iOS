//
//  FoodClassifierRepresentable.swift
//  Core
//
//  Created by Kai Lee on 1/18/26.
//

import UIKit

public protocol FoodClassifierRepresentable {
    func classify(image: UIImage) throws -> FoodClassificationResult
}

public extension FoodClassifierRepresentable {
    func isFood(
        image: UIImage,
        threshold: Float = 0.75
    ) throws -> Bool {
        let result = try classify(image: image)
        switch result {
        case let .food(confidence):
            return confidence >= threshold
        case .notFood:
            return false
        }
    }
}
