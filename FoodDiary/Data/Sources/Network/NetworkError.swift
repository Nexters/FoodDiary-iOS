//
//  NetworkError.swift
//  Core
//
//  Created by 강대훈 on 1/17/26.
//

import Foundation

public enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case encodingError
    case decodingError
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case unknown
}
