//
//  PhotosEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/16/26.
//

import Domain
import Foundation

public enum PhotosEndpoint {
    case batchUpload(date: String, deviceId: String, photos: [File], testMode: Bool)
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
        case .batchUpload:
            "/photos/batch-upload"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .batchUpload:
            .post
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case let .batchUpload(_, _, _, testMode):
            testMode ? ["test_mode": "true"] : nil
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case let .batchUpload(date, deviceId, photos, _):
            return .multipart(
                MultipartFormData(
                    date: date,
                    deviceId: deviceId,
                    photos: photos
                )
            )
        }
    }

    public var headers: [String : String] {
        switch self {
        case .batchUpload:
            [:]
        }
    }
}
