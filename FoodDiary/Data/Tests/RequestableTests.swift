//
//  RequestableTests.swift
//  CoreTests
//
//  Created by 강대훈 on 1/18/26.
//

import Foundation
import Testing
@testable import Data

struct RequestableTests {
    @Test("URLRequest가 잘 생성되는지")
    func createURLRequest() throws {
        let _ = try MockEndpoint.minimal.makeURLRequest()
        let _ = try MockEndpoint.full.makeURLRequest()
    }

    @Test("URL이 잘 생성되는지")
    func createURL() throws {
        let expected = URL(string: "https://api.example.com/health")
        let request = try MockEndpoint.minimal.makeURLRequest()

        let url = try #require(request.url)

        #expect(url == expected)
    }

    @Test("쿼리 파라미터가 잘 만들어지는지")
    func testQueryParameter() throws {
        let expected = [URLQueryItem(name: "tests", value: "1")]
        let request = try MockEndpoint.full.makeURLRequest()

        let url = try #require(request.url)
        let urlComponents = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(urlComponents.queryItems)

        #expect(queryItems == expected)
    }

    @Test("바디 파라미터가 잘 만들어지는지")
    func testBodyParameter() throws {
        let expectedName = "Kang"
        let expectedAge = 999
        let request = try MockEndpoint.full.makeURLRequest()

        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body, options: [])
        let typeCastedJson = try #require(json as? [String: Any])

        #expect(typeCastedJson["name"] as? String == expectedName)
        #expect(typeCastedJson["age"] as? Int == expectedAge)
    }

    @Test("헤더가 잘 만들어지는지")
    func testHeaders() throws {
        let expected = "kang"
        let request = try MockEndpoint.full.makeURLRequest()

        let headers = try #require(request.allHTTPHeaderFields)

        #expect(headers["X-Test-Header"] == expected)
    }

    @Test("json body일 때 Content-Type이 application/json으로 설정된다")
    func testJsonContentTypeHeader() throws {
        let request = try MockEndpoint.full.makeURLRequest()

        let headers = try #require(request.allHTTPHeaderFields)

        #expect(headers["Content-Type"] == "application/json")
    }

    @Test("multipart body가 URLRequest의 httpBody에 올바르게 설정된다")
    func testMultipartBody() throws {
        let formData = MultipartFormData(
            date: "2026-02-17",
            deviceId: "abcd",
            photos: [
                File(fileName: "photo1.jpg", mimeType: "image/jpeg", data: "dummy-1".data(using: .utf8)!),
                File(fileName: "photo2.jpg", mimeType: "image/jpeg", data: "dummy-2".data(using: .utf8)!)
            ]
        )
        let request = try MockEndpoint.multipart(formData).makeURLRequest()

        let body = try #require(request.httpBody)

        #expect(body == formData.body)
    }

    @Test("multipart body일 때 Content-Type 헤더가 formData의 contentType으로 설정된다")
    func testMultipartContentTypeHeader() throws {
        let formData = MultipartFormData(
            date: "2026-02-17",
            deviceId: "abcd",
            photos: [
                File(fileName: "photo1.jpg", mimeType: "image/jpeg", data: "dummy-1".data(using: .utf8)!),
                File(fileName: "photo2.jpg", mimeType: "image/jpeg", data: "dummy-2".data(using: .utf8)!)
            ]
        )
        let request = try MockEndpoint.multipart(formData).makeURLRequest()

        let headers = try #require(request.allHTTPHeaderFields)

        #expect(headers["Content-Type"] == formData.contentType)
    }
}
