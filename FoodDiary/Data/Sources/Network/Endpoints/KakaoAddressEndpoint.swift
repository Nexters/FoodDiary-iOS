//
//  KakaoAddressEndpoint.swift
//  Data
//

import Foundation

enum KakaoAddressEndpoint {
    case searchKeyword(query: String, page: Int)
}

extension KakaoAddressEndpoint: Requestable {
    var baseURL: String {
        "https://dapi.kakao.com"
    }

    var path: String {
        switch self {
        case .searchKeyword:
            "/v2/local/search/keyword.json"
        }
    }

    var httpMethod: HTTPMethod {
        .get
    }

    var queryParameters: Encodable? {
        switch self {
        case .searchKeyword(let query, let page):
            ["query": query, "page": "\(page)", "size": "15"]
        }
    }

    var bodyParameters: Encodable? {
        nil
    }

    var headers: [String: String] {
        guard let apiKey = Bundle.main.infoDictionary?["KAKAO_REST_API_KEY"] as? String else {
            fatalError("KAKAO_REST_API_KEY가 Info.plist에 설정되지 않았습니다.")
        }
        return ["Authorization": "KakaoAK \(apiKey)"]
    }
}
