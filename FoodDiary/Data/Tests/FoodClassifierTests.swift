//
//  FoodClassifierTests.swift
//  Core
//
//  Created by Kai Lee on 1/18/26.
//

@testable import Data
import Testing
import UIKit

// MARK: - Mock

struct MockFoodClassifier: FoodClassifierRepresentable {
    var stubResult: FoodClassificationResult = .food(confidence: 0.95)
    var shouldThrowError: Bool = false

    func classify(image _: UIImage) throws -> FoodClassificationResult {
        if shouldThrowError {
            throw MockError.classificationFailed
        }
        return stubResult
    }

    enum MockError: Error {
        case classificationFailed
    }
}

// MARK: - Tests

@Suite("FoodClassifier Tests")
struct FoodClassifierTests {
    private let confidence: Float = 0.9

    // MARK: - classify 테스트

    @Test("classify가 food 결과를 반환")
    func testClassifyReturnsFood() throws {
        var classifier = MockFoodClassifier()
        classifier.stubResult = .food(confidence: confidence)

        let dummyImage = UIImage()
        let result = try classifier.classify(image: dummyImage)

        switch result {
        case let .food(confidence):
            #expect(confidence == confidence)
        case .notFood:
            Issue.record("food를 반환해야 합니다")
        }
    }

    @Test("classify가 notFood 결과를 반환")
    func testClassifyReturnsNotFood() throws {
        var classifier = MockFoodClassifier()
        classifier.stubResult = .notFood(confidence: confidence)

        let dummyImage = UIImage()
        let result = try classifier.classify(image: dummyImage)

        switch result {
        case .food:
            Issue.record("notFood를 반환해야 합니다")
        case let .notFood(confidence):
            #expect(confidence == confidence)
        }
    }

    @Test("classify 에러 발생")
    func testClassifyThrowsError() throws {
        var classifier = MockFoodClassifier()
        classifier.shouldThrowError = true

        let dummyImage = UIImage()

        #expect(throws: MockFoodClassifier.MockError.self) {
            try classifier.classify(image: dummyImage)
        }
    }

    // MARK: - isFood 테스트

    @Test("음식으로 분류되면 isFood가 true를 반환")
    func testIsFoodReturnsTrue() throws {
        var classifier = MockFoodClassifier()
        classifier.stubResult = .food(confidence: confidence)

        let dummyImage = UIImage()
        let result = try classifier.isFood(image: dummyImage)

        #expect(result == true)
    }

    @Test("음식이 아닌 것으로 분류되면 isFood가 false를 반환")
    func testIsFoodReturnsFalse() throws {
        var classifier = MockFoodClassifier()
        classifier.stubResult = .notFood(confidence: confidence)

        let dummyImage = UIImage()
        let result = try classifier.isFood(image: dummyImage)

        #expect(result == false)
    }

    @Test("음식 confidence가 threshold 미만이면 isFood가 false를 반환")
    func testIsFoodReturnsFalseWhenBelowThreshold() throws {
        var classifier = MockFoodClassifier()
        classifier.stubResult = .food(confidence: 0.5)

        let dummyImage = UIImage()
        let result = try classifier.isFood(image: dummyImage, threshold: 0.75)

        #expect(result == false)
    }

    @Test("커스텀 threshold로 isFood 판단")
    func testIsFoodWithCustomThreshold() throws {
        var classifier = MockFoodClassifier()
        classifier.stubResult = .food(confidence: 0.6)

        let dummyImage = UIImage()

        #expect(try classifier.isFood(image: dummyImage, threshold: 0.5) == true)
        #expect(try classifier.isFood(image: dummyImage, threshold: 0.7) == false)
    }

    @Test("classify 에러 발생 시 isFood도 에러 propagate")
    func testIsFoodThrowsError() throws {
        var classifier = MockFoodClassifier()
        classifier.shouldThrowError = true

        let dummyImage = UIImage()

        #expect(throws: MockFoodClassifier.MockError.self) {
            try classifier.isFood(image: dummyImage)
        }
    }
}
