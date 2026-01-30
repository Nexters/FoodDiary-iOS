//
//  MockHTTPClient.swift
//  Data
//
//  Created by 강대훈 on 1/27/26.
//

@testable import Data

final class MockHTTPClient: HTTPClienting {
    typealias Target = AuthEndpoint
    
    private(set) var callCount = 0
    var throwError: Bool
    var stubResponse: AuthResponseDTO?
    
    init(throwError: Bool = false) {
        self.throwError = throwError
    }
    
    func request<T: Decodable>(_ request: AuthEndpoint, accessToken: String? = nil) async throws -> T {
        callCount += 1
        
        if throwError {
            throw NetworkError.httpError(statusCode: 400, data: nil)
        }
        
        if let response = stubResponse as? T {
            return response
        }
        
        fatalError("MockHTTPClient.request should not be called without configuring stubAuthResponse")
    }
}
