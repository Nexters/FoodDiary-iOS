//
//  LoginSession.swift
//  Domain
//
//  Created by 강대훈 on 4/10/26.
//

// TODO: 추후 적절한 레이어로 이동 예정

import Combine

public final class LoginSession {
    private let loginResultSubject = PassthroughSubject<LoginResult, Never>()
    private let logoutSubject = PassthroughSubject<Void, Never>()

    public var loginResultPublisher: AnyPublisher<LoginResult, Never> {
        loginResultSubject.eraseToAnyPublisher()
    }

    public var logoutPublisher: AnyPublisher<Void, Never> {
        logoutSubject.eraseToAnyPublisher()
    }

    public init() {}

    public func notifyLoginSuccess(_ result: LoginResult) {
        loginResultSubject.send(result)
    }

    public func notifyLogout() {
        logoutSubject.send()
    }
}
