//
//  FoodRecordError.swift
//  Domain
//

import Foundation

public enum FoodRecordError: Error {
    case noAccessToken
    case imageConversionFailed
    case emptyResponse
}
