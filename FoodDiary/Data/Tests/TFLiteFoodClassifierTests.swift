//
//  TFLiteFoodClassifierTests.swift
//  Data
//
//  Created by Kai Lee on 1/18/26.
//

@testable import Data
import Testing
import UIKit

@Suite("TFLiteFoodClassifier Tests")
struct TFLiteFoodClassifierTests {
    private let confidenceThreshold: Float = 0.75

    private var dataBundle: Bundle {
        Bundle(identifier: "com.fooddiary.data")!
    }

    private var testBundle: Bundle {
        Bundle(for: BundleFinder.self)
    }

    private var modelPath: String? {
        dataBundle.path(forResource: "food_classifier", ofType: "tflite")
    }

    private var testImageURLs: [URL] {
        guard let resourceURL = testBundle.resourceURL else { return [] }

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return contents.filter { url in
            let ext = url.pathExtension.lowercased()
            return ["jpg", "jpeg", "png"].contains(ext)
        }
    }

    @Test("모델 로드")
    func testModelLoading() throws {
        #expect(modelPath != nil, "모델 파일이 존재해야 합니다")
        _ = try TFLiteFoodClassifier(modelPath: modelPath!)
    }

    @Test("음식 이미지 분류")
    func testClassifyFoodImages() throws {
        let classifier = try TFLiteFoodClassifier(modelPath: modelPath!)
        let foodImageURLs = testImageURLs.filter { $0.lastPathComponent.hasPrefix("food") }

        #expect(!foodImageURLs.isEmpty, "food로 시작하는 테스트 이미지가 있어야 합니다")

        for imageURL in foodImageURLs {
            guard let image = UIImage(contentsOfFile: imageURL.path) else {
                Issue.record("이미지를 로드할 수 없습니다: \(imageURL.lastPathComponent)")
                continue
            }

            let result = try classifier.classify(image: image)
            let imageName = imageURL.lastPathComponent

            switch result {
            case let .food(confidence):
                #expect(confidence > confidenceThreshold, "\(imageName): 높은 확신도를 가져야 합니다 (0.75 이상)")
                #expect(try classifier.isFood(image: image), "\(imageName): 음식으로 분류되어야 합니다")
            case .notFood:
                Issue.record("\(imageName): 음식 이미지가 음식으로 분류되어야 합니다")
            }
        }
    }

    @Test("음식이 아닌 이미지 분류")
    func testClassifyNotFoodImages() throws {
        let classifier = try TFLiteFoodClassifier(modelPath: modelPath!)
        let notFoodImageURLs = testImageURLs.filter { $0.lastPathComponent.hasPrefix("non-food") }

        #expect(!notFoodImageURLs.isEmpty, "non-food로 시작하는 테스트 이미지가 있어야 합니다")

        for imageURL in notFoodImageURLs {
            guard let image = UIImage(contentsOfFile: imageURL.path) else {
                Issue.record("이미지를 로드할 수 없습니다: \(imageURL.lastPathComponent)")
                continue
            }

            let result = try classifier.classify(image: image)
            let imageName = imageURL.lastPathComponent

            switch result {
            case .food:
                Issue.record("\(imageName): 음식이 아닌 이미지는 notFood로 분류되어야 합니다")
            case let .notFood(confidence):
                #expect(confidence > confidenceThreshold, "\(imageName): 높은 확신도를 가져야 합니다 (0.75 이상)")
                #expect(try !classifier.isFood(image: image), "\(imageName): 음식이 아닌 이미지로 분류되어야 합니다")
            }
        }
    }
}

private final class BundleFinder {}
