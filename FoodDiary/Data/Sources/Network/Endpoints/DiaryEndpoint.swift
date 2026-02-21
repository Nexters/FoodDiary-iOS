//
//  DiaryEndpoint.swift
//  Data
//
//  Created by 강대훈 on 2/18/26.
//

import Foundation

public enum DiaryEndpoint {
    case byDateRange(startDate: String, endDate: String, testMode: Bool)
    case byDateRangeSummary(startDate: String, endDate: String, testMode: Bool)
    case update(diaryId: Int, body: DiaryUpdateRequestDTO)
    case suggestions(diaryId: Int)
    case delete(diaryId: Int)
    case addPhotos(diaryId: Int, photos: [File])
}

extension DiaryEndpoint: Requestable {
    public var baseURL: String {
        guard let url = Bundle.main.infoDictionary?["BASE_URL"] as? String else {
            fatalError("BASE_URL이 Info.plist에 설정되지 않았습니다.")
        }

        return url
    }

    public var path: String {
        switch self {
        case .byDateRange:
            "/diaries"
        case .byDateRangeSummary:
            "/diaries/summary"
        case .update(let diaryId, _):
            "/diaries/\(diaryId)"
        case .delete(let diaryId):
            "/diaries/\(diaryId)"
        case .suggestions(let diaryId):
            "/diaries/\(diaryId)/suggestions"
        case .addPhotos(let diaryId, _):
            "/diaries/\(diaryId)/photos"
        }
    }

    public var httpMethod: HTTPMethod {
        switch self {
        case .byDateRange, .byDateRangeSummary, .suggestions:
            .get
        case .update:
            .patch
        case .delete:
            .delete
        case .addPhotos:
            .post
        }
    }

    public var queryParameters: Encodable? {
        switch self {
        case let .byDateRange(startDate, endDate, testMode):
            var params: [String: String] = [
                "start_date": startDate,
                "end_date": endDate
            ]
            if testMode {
                params["test_mode"] = "true"
            }
            return params
        case let .byDateRangeSummary(startDate, endDate, testMode):
            var params: [String: String] = [
                "start_date": startDate,
                "end_date": endDate
            ]
            if testMode {
                params["test_mode"] = "true"
            }
            return params
        case .update, .delete, .suggestions, .addPhotos:
            return nil
        }
    }

    public var bodyParameters: HTTPBody {
        switch self {
        case .byDateRange, .byDateRangeSummary, .delete, .suggestions:
            .none
        case .update(_, let body):
            .json(body)
        case .addPhotos(_, let photos):
            .photosMultipart(PhotosMultipartFormData(photos: photos))
        }
    }

    public var headers: [String: String] {
        [:]
    }
}
