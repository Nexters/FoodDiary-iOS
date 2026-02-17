//
//  HTTPClientTests.swift
//  DataTests
//

import Foundation
import Testing
@testable import Data

struct HTTPClientTests {
    @Test("Request 성공 시 디코딩된 모델을 반환한다")
    func request_whenSuccess_returnsDecodedModel() async throws {
        let expectedResponse = MockResponseDTO(id: "123", message: "success")
        let jsonData = try JSONEncoder().encode(expectedResponse)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, jsonData)
        }

        let session = MockURLProtocol.makeSession()
        let sut = HTTPClient(session: session)

        let result: MockResponseDTO = try await sut.request(MockEndpoint.minimal)

        #expect(result == expectedResponse)
    }

    @Test("makeURLRequest 실패 시 NetworkError.invalidURL을 던진다")
    func request_whenInvalidURL_throwsInvalidURLError() async throws {
        let session = MockURLProtocol.makeSession()
        let sut = HTTPClient(session: session)
        
        let error = await #expect(throws: NetworkError.self) {
            struct InvalidEndpoint: Requestable {
                var baseURL: String { "" }
                var path: String { "" }
                var httpMethod: HTTPMethod { .get }
                var queryParameters: Encodable? { nil }
                var bodyParameters: HTTPBody { .none }
                var headers: [String: String] { [:] }
            }
            
            let _: MockResponseDTO = try await sut.request(InvalidEndpoint())
        }

        guard case .invalidURL = error else {
            Issue.record("NetworkError.invalidURL을 예상했지만 \(String(describing: error))가 발생함")
            return
        }
    }

    @Test("session.data(for:) 실패 시 NetworkError.requestFailed로 처리된다")
    func request_whenSessionFails_throwsUnknownError() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: [NSLocalizedDescriptionKey: "The internet connection appears to be offline."]
            )
        }

        let session = MockURLProtocol.makeSession()
        let sut = HTTPClient(session: session)

        let error = await #expect(throws: NetworkError.self) {
            let _: MockResponseDTO = try await sut.request(MockEndpoint.minimal)
        }
        
        guard case .requestFailed = error else {
            Issue.record("NetworkError.requestFailed를 예상했지만 \(String(describing: error))가 발생함")
            return
        }
    }
    
    @Test("Response를 HTTPURLResponse로 다운캐스팅 실패 시 NetworkError.invalidResponse로 처리된다")
    func request_whenInvalidResponse_throwsInvalidResponseError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 5,
                textEncodingName: nil
            )
            
            return (response, Data())
        }
        
        let session = MockURLProtocol.makeSession()
        let sut = HTTPClient(session: session)
        
        let error = await #expect(throws: NetworkError.self) {
            let _: MockResponseDTO = try await sut.request(MockEndpoint.minimal)
        }
        
        guard case .invalidResponse = error else {
            Issue.record("NetworkError.invalidResponse를 예상했지만 \(String(describing: error))가 발생함")
            return
        }
    }
    
    @Test("Response가 200번대가 아닐 시 NetworkError.httpError로 처리된다")
    func request_whenNon2xxStatusCode_throwsHttpError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data())
        }
        
        let session = MockURLProtocol.makeSession()
        let sut = HTTPClient(session: session)
        
        let error = await #expect(throws: NetworkError.self) {
            let _: MockResponseDTO = try await sut.request(MockEndpoint.minimal)
        }
        
        guard case .httpError = error else {
            Issue.record("NetworkError.httpError를 예상했지만 \(String(describing: error))가 발생함")
            return
        }
    }
    
    @Test("Decode 실패 시 NetworkError.decodingError로 처리된다")
    func request_whenDecodingFails_throwsDecodingError() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data())
        }
        
        let session = MockURLProtocol.makeSession()
        let sut = HTTPClient(session: session)
        
        let error = await #expect(throws: NetworkError.self) {
            let _: MockResponseDTO = try await sut.request(MockEndpoint.minimal)
        }
        
        guard case .decodingError = error else {
            Issue.record("NetworkError.decodingError를 예상했지만 \(String(describing: error))가 발생함")
            return
        }
    }
}
