//
//  RequestableTests.swift
//  CoreTests
//
//  Created by 강대훈 on 1/18/26.
//

import Foundation
import Testing
@testable import Core

struct RequestableTests {
    @Test("URLRequest가 잘 생성되는지")
    func createURLRequest() throws {
        let _ = try MockEndpoint.minimal.makeURLrequest()
        let _ = try MockEndpoint.full.makeURLrequest()
    }

    @Test("URL이 잘 생성되는지")
    func createURL() throws {
        let expected = URL(string: "https://api.example.com/health")
        let request = try MockEndpoint.minimal.makeURLrequest()

        let url = try #require(request.url)

        #expect(url == expected)
    }

    @Test("쿼리 파라미터가 잘 만들어지는지")
    func testQueryParameter() throws {
        let expected = [URLQueryItem(name: "tests", value: "1")]
        let request = try MockEndpoint.full.makeURLrequest()

        let url = try #require(request.url)
        let urlComponents = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = try #require(urlComponents.queryItems)

        #expect(queryItems == expected)
    }

    @Test("바디 파라미터가 잘 만들어지는지")
    func testBodyParameter() throws {
        let expectedName = "Kang"
        let expectedAge = 999
        let request = try MockEndpoint.full.makeURLrequest()

        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body, options: [])
        let typeCastedJson = try #require(json as? [String: Any])

        #expect(typeCastedJson["name"] as? String == expectedName)
        #expect(typeCastedJson["age"] as? Int == expectedAge)
    }

    @Test("헤더가 잘 만들어지는지")
    func testHeaders() throws {
        let expected = "kang"
        let request = try MockEndpoint.full.makeURLrequest()

        let headers = try #require(request.allHTTPHeaderFields)

        #expect(headers["X-Test-Header"] == expected)
    }
}
