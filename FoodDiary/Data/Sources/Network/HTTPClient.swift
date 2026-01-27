//
//  HTTPClient.swift
//  Core
//
//  Created by 강대훈 on 1/17/26.
//

import Foundation

public class HTTPClient<Target: Requestable> {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    public init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
    }
    
    public func request<T: Decodable>(_ request: Target, accessToken: String? = nil) async throws -> T {
        var urlRequest = try request.makeURLRequest()
        applyAccessToken(accessToken, to: &urlRequest)
        let (data, response) = try await session.data(for: urlRequest)
        try checkResponse(data, response)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}

// MARK: - Private Method
private extension HTTPClient {
    func applyAccessToken(_ accessToken: String?, to request: inout URLRequest) {
        guard let accessToken else { return }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
    
    func checkResponse(_ data: Data, _ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // TODO: 네트워크 에러 핸들링 정의되고 나서 로직 재구현 예정.
        switch httpResponse.statusCode {
        case 200..<300:
            return
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
    }
}
