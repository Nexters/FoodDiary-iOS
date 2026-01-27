//
//  MockHTTPClient.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

@testable import Data

final class MockHTTPClient: HTTPClient<AuthEndpoint> {
    private(set) var callCount = 0
    var throwError: Bool
    
    init(throwError: Bool = false) {
        self.throwError = throwError
    }
    
    override func request<T: Decodable>(_ request: AuthEndpoint, accessToken: String? = nil) async throws -> T {
        callCount += 1
        
        if throwError {
            throw NetworkError.httpError(statusCode: 400, data: nil)
        }
        
        fatalError("MockHTTPClient.request should not be called without configuring errorToThrow")
    }
}
