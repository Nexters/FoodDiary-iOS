//
//  TokenRepositoryTests.swift
//  DataTests
//
//  Created by 강대훈 on 1/27/26.
//

import Foundation
import Testing
import Domain
@testable import Data

struct TokenRepositoryTests {
    @Test("identityToken을 String으로 만들 수 없으면 AppleLoginError를 던지고, HTTPClient/TokenManager가 호출되지 않는다")
    func save_whenStringInitFails_throwsErrorAndDoesNotCallDependencies() async {
        let httpClient = MockHTTPClient()
        let tokenManager = MockTokenManager()
        let sut = TokenRepositoryImpl(httpClient: httpClient, tokenManager: tokenManager)
        let invalidData = Data([0xFF])
        
        let error = await #expect(throws: AppleLoginError.tokenPersistenceFailed) {
            _ = try await sut.save(invalidData)
        }
        
        #expect(error == .tokenPersistenceFailed)
        #expect(httpClient.callCount == 0)
        #expect(tokenManager.setCallCount == 0)
        #expect(tokenManager.lastToken == nil)
    }

    @Test("String 변환은 성공하지만 HTTP 요청에서 에러가 나면, 에러를 그대로 던지고 Token은 저장되지 않는다")
    func save_whenRequestFails_propagatesErrorAndDoesNotSaveToken() async {
        let httpClient = MockHTTPClient(throwError: true)
        let tokenManager = MockTokenManager()
        let sut = TokenRepositoryImpl(httpClient: httpClient, tokenManager: tokenManager)
        
        let validString = "valid_identity_token"
        let validData = Data(validString.utf8)
        
        let error = await #expect(throws: NetworkError.self) {
            _ = try await sut.save(validData)
        }
        
        if case .httpError = error {
            #expect(httpClient.callCount == 1)
            #expect(tokenManager.setCallCount == 0)
            #expect(tokenManager.lastToken == nil)
        } else {
            Issue.record("NetworkError.httpError를 예상했지만, 실제 에러는 다음과 같습니다. \(error)")
        }
    }

    @Test("HTTP 요청은 성공하지만 TokenManager.set에서 AppleLoginError.tokenPersistenceFailed를 던지면 그대로 전파된다")
    func save_whenTokenManagerSetFails_propagatesAppleLoginError() async {
        let httpClient = MockHTTPClient()
        let tokenManager = MockTokenManager()
        tokenManager.shouldThrow = true
        let sut = TokenRepositoryImpl(httpClient: httpClient, tokenManager: tokenManager)
        
        let validString = "valid_identity_token"
        let validData = Data(validString.utf8)
        
        httpClient.stubResponse = AuthResponseDTO(accessToken: "access_token", id: "id", isFirst: false)
        
        let error = await #expect(throws: AppleLoginError.self) {
            _ = try await sut.save(validData)
        }
        
        #expect(error == .tokenPersistenceFailed)
        #expect(httpClient.callCount == 1)
        #expect(tokenManager.setCallCount == 1)
        #expect(tokenManager.lastToken == nil)
    }

    @Test("정상적으로 모두 성공하면 LoginResult를 반환한다")
    func save_whenAllSuccess_returnsLoginResultAndCallsDependencies() async throws {
        let httpClient = MockHTTPClient()
        let tokenManager = MockTokenManager()
        let sut = TokenRepositoryImpl(httpClient: httpClient, tokenManager: tokenManager)
        
        let identityTokenString = "valid_identity_token"
        let identityTokenData = Data(identityTokenString.utf8)
        let expectedLoginResult = LoginResult(isFirst: true)
        
        httpClient.stubResponse = AuthResponseDTO(
            accessToken: "saved_access_token",
            id: "some_id",
            isFirst: true
        )
        
        let result = try await sut.save(identityTokenData)
        
        #expect(result.isFirst == expectedLoginResult.isFirst)
        #expect(httpClient.callCount == 1)
        #expect(tokenManager.setCallCount == 1)
        #expect(tokenManager.lastToken == "saved_access_token")
    }
}


