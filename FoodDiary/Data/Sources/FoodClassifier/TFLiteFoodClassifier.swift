//
//  TFLiteFoodClassifier.swift
//  Data
//
//  Created by Kai Lee on 1/18/26.
//

import Foundation
import os
import TensorFlowLiteSwift
import Domain
import UIKit

public struct TFLiteFoodClassifier: FoodClassifierRepresentable {
    public static let modelFileName = "food_classifier"
    public static let modelType = "tflite"

    private let interpreter: Interpreter
    private let inputWidth: Int
    private let inputHeight: Int
    private let lock = UnfairLock()

    // MARK: - Initialization

    public init(
        modelName: String = Self.modelFileName,
        modelType: String = Self.modelType,
    ) throws {
        guard let bundle = Bundle(identifier: "com.fooddiary.data"),
              let modelPath = bundle.path(forResource: modelName, ofType: modelType) else {
            throw TFLiteFoodClassifierError.modelNotFound
        }
        
        try self.init(modelPath: modelPath)
    }

    public init(modelPath: String) throws {
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw TFLiteFoodClassifierError.modelNotFound
        }

        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()

            let inputTensor = try interpreter.input(at: 0)
            let inputShape = inputTensor.shape.dimensions

            inputHeight = inputShape[1]
            inputWidth = inputShape[2]
        } catch {
            throw TFLiteFoodClassifierError.failedToCreateInterpreter
        }
    }

    // MARK: - Classification

    public func classify(image: UIImage) throws -> FoodClassificationResult {
        guard let pixelBuffer = preprocessImage(image) else {
            throw TFLiteFoodClassifierError.failedToProcessImage
        }

        lock.lock()
        defer { lock.unlock() }

        do {
            try interpreter.copy(pixelBuffer, toInputAt: 0)
            try interpreter.invoke()

            let outputTensor = try interpreter.output(at: 0)
            let outputData = outputTensor.data

            let results: [UInt8] = outputData.withUnsafeBytes { pointer in
                Array(pointer.bindMemory(to: UInt8.self))
            }

            // food-not-food 모델: [food, not_food] 순서
            // UInt8 (0-255) → Float (0-1) 변환
            let foodConfidence = Float(results[0]) / 255.0
            let notFoodConfidence = Float(results[1]) / 255.0

            if foodConfidence > notFoodConfidence {
                return .food(confidence: foodConfidence)
            } else {
                return .notFood(confidence: notFoodConfidence)
            }
        } catch {
            throw TFLiteFoodClassifierError.failedToCopyData
        }
    }
}

private extension TFLiteFoodClassifier {
    func preprocessImage(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let width = inputWidth
        let height = inputHeight
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // RGBA에서 RGB만 추출 (UInt8 형식 유지)
        var rgbData = [UInt8]()
        rgbData.reserveCapacity(width * height * 3)

        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = (y * width + x) * bytesPerPixel
                rgbData.append(pixelData[offset]) // R
                rgbData.append(pixelData[offset + 1]) // G
                rgbData.append(pixelData[offset + 2]) // B
            }
        }

        return Data(rgbData)
    }
}

public extension TFLiteFoodClassifier {
    enum TFLiteFoodClassifierError: LocalizedError {
        case modelNotFound
        case failedToCreateInterpreter
        case failedToAllocateTensors
        case failedToGetInputTensor
        case failedToGetOutputTensor
        case failedToProcessImage
        case failedToCopyData

        public var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "모델 파일을 찾을 수 없습니다."
            case .failedToCreateInterpreter:
                return "인터프리터 생성에 실패했습니다."
            case .failedToAllocateTensors:
                return "텐서 할당에 실패했습니다."
            case .failedToGetInputTensor:
                return "입력 텐서를 가져오는 데 실패했습니다."
            case .failedToGetOutputTensor:
                return "출력 텐서를 가져오는 데 실패했습니다."
            case .failedToProcessImage:
                return "이미지 전처리에 실패했습니다."
            case .failedToCopyData:
                return "데이터 복사에 실패했습니다."
            }
        }
    }
}
