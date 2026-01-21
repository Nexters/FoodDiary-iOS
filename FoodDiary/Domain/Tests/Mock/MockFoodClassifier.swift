//
//  MockFoodClassifier.swift
//  Domain
//
//  Created by Kai Lee on 1/21/26.
//

@testable import Domain
import UIKit

final class MockFoodClassifier: FoodClassifierRepresentable {
    var classifyResults: [FoodClassificationResult] = []
    private var callCount = 0
    private let lock = NSLock()

    func classify(image: UIImage) throws -> FoodClassificationResult {
        lock.lock()
        defer {
            callCount += 1
            lock.unlock()
        }

        if callCount < classifyResults.count {
            return classifyResults[callCount]
        }
        return .notFood(confidence: 0.9)
    }
}
