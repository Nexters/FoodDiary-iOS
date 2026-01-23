//
//  AuthenticatedHTTPClient.swift
//  Data
//
//  Created by 강대훈 on 1/23/26.
//

import Domain

/// JWT를 사용하며, HTTPClient를 래핑한 객체입니다.
public final class AuthenticatedHTTPClient<Target: Requestable> {
    private let baseClient: HTTPClient<Target>
    private let tokenManager: TokenManaging
    
    init(baseClient: HTTPClient<Target>, tokenManager: TokenManaging) {
        self.baseClient = baseClient
        self.tokenManager = tokenManager
    }
}
