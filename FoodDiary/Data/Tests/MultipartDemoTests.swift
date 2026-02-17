//
//  MultipartDemoTests.swift
//  DataTests
//
//  Created by 강대훈 on 2/17/26.
//
//  ⚠️ 이 파일은 실제 서버와 통신하는 통합 데모 테스트입니다.
//  리뷰 시 아래 baseURL을 실제 서버 주소로 변경 후 직접 실행하세요.
//

import Foundation
import Testing
@testable import Data

// MARK: - Demo Endpoint

private struct BatchUploadDemoEndpoint: Requestable {
    let date: String
    let photos: [File]

    var baseURL: String { "" } // MARK: ← 실제 서버 주소로 교체
    var path: String { "/photos/batch-upload" }
    var httpMethod: HTTPMethod { .post }
    var queryParameters: Encodable? { ["test_mode": "true"] }
    var bodyParameters: HTTPBody { .multipart(MultipartFormData(date: date, photos: photos)) }
    var headers: [String: String] { [:] }
}

// MARK: - Demo Tests

struct MultipartDemoTests {

    @Test("multipart/form-data 배치 업로드 실제 통신 데모")
    func batchUpload_withRealHTTPClient_returnsResponse() async throws {
        let client = HTTPClient()
        
        let endpoint = BatchUploadDemoEndpoint(
            date: "2026-02-17",
            photos: [
                File(
                    fileName: "demo1.jpg",
                    mimeType: "image/jpeg",
                    data: Data(repeating: 0xFF, count: 1024)
                ),
                File(
                    fileName: "demo2.jpg",
                    mimeType: "image/jpeg",
                    data: Data(repeating: 0xFF, count: 1024)
                )
            ]
        )
        
        // MARK: accessToken 주입해야 함!!
        let response: BatchUploadResponseDTO = try await client.request(endpoint, accessToken: "")

        #expect(!response.results.isEmpty)
    }
}
