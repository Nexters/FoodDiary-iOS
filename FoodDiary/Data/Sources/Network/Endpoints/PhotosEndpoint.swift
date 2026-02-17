//
//  PhotosEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/16/26.
//

import Domain
import Foundation

public enum PhotosEndpoint {
    case batchUploadTest(date: String, photos: [File])
}

extension PhotosEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }
        
        return url
    }
    
    public var path: String {
        switch self {
        case .batchUploadTest:
            "/photos/batch-upload"
        }
    }
    
    public var httpMethod: HTTPMethod {
        switch self {
        case .batchUploadTest:
            .post
        }
    }
    
    public var queryParameters: Encodable? {
        switch self {
        case .batchUploadTest:
            ["test_mode": "true"]
        }
    }
    
    public var bodyParameters: HTTPBody {
        switch self {
        case let .batchUploadTest(date, photos):
            return .multipart(
                MultipartFormData(
                    date: date,
                    photos: photos
                )
            )
        }
    }
    
    public var headers: [String : String] {
        switch self {
        case .batchUploadTest:
            [:]
        }
    }
}
