//
//  TokenManagerTests.swift
//  DataTests
//
//  Created by 강대훈 on 1/27/26.
//

import Testing
import Domain
@testable import Data

// MARK: - TokenManagerTests

struct TokenManagerTests {
    @Test("토큰 저장 후 Load 시에 저장된 토큰을 반환한다")
    func loadToken_success_returnsSavedToken() throws {
        let keychainService = InMemoryKeychainService()
        let sut = TokenManager(keychainService: keychainService)
        let expectedToken = "test_token"
        try sut.set(expectedToken)
        
        let loadedToken = sut.get()
        
        #expect(loadedToken == expectedToken)
    }
    
    @Test("저장된 토큰이 없으면 Load 시에 nil을 반환한다")
    func loadToken_failure_returnsNil() {
        let keychainService = InMemoryKeychainService()
        let sut = TokenManager(keychainService: keychainService)
        
        let loadedToken = sut.get()
        
        #expect(loadedToken == nil)
    }
    
    @Test("Set 성공 시 토큰이 저장되고 에러가 발생하지 않는다")
    func setToken_success_tokenIsPersisted() throws {
        let keychainService = InMemoryKeychainService()
        let sut = TokenManager(keychainService: keychainService)
        let token = "persist_token"
        
        try sut.set(token)
        
        let loadedToken = sut.get()
        #expect(loadedToken == token)
    }
    
    @Test("Set 실패 시 에러를 던진다")
    func setToken_failure_throwsTokenPersistenceFailed() {
        let keychainService = InMemoryKeychainService()
        keychainService.shouldSaveSucceed = false
        let sut = TokenManager(keychainService: keychainService)
        let token = "will_fail"
        
        let error = #expect(throws: AppleLoginError.tokenPersistenceFailed) {
            try sut.set(token)
        }
        
        #expect(error == .tokenPersistenceFailed)
    }
    
    @Test("토큰 저장 후 Clear 시 토큰이 제대로 삭제된다")
    func clearToken_success_tokenIsDeleted() throws {
        let keychainService = InMemoryKeychainService()
        let sut = TokenManager(keychainService: keychainService)
        let token = "test_token_to_delete"
        try sut.set(token)
        
        try sut.clear()
        
        let loadedToken = sut.get()
        #expect(loadedToken == nil)
    }
    
    @Test("토큰 저장 후 Clear 실패 시 에러를 던진다")
    func clearToken_failure_throwsTokenPersistenceFailed() {
        let keychainService = InMemoryKeychainService()
        keychainService.shouldDeleteSucceed = false
        let sut = TokenManager(keychainService: keychainService)
        let token = "test_token"
        try? sut.set(token)
        
        let _ = #expect(throws: AppleLoginError.tokenDecodingFailed) {
            try sut.clear()
        }
    }
}


