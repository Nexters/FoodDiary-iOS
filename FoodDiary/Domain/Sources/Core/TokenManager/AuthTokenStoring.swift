//
//  AuthTokenStoring.swift
//  Domain
//
//  Created by 강대훈 on 1/23/26.
//

import Foundation

/// 인증 토큰(Access Token)을 저장하고 관리하는 프로토콜
public protocol AuthTokenStoring {
    /// 저장된 인증 토큰을 가져옴
    /// - Returns: 인증 토큰 문자열, 없을 경우 nil
    func get() -> String?

    /// 인증 토큰을 저장
    /// - Parameter token: 저장할 인증 토큰
    /// - Throws: 저장 실패 시 에러
    func set(_ token: String) throws

    /// 저장된 인증 토큰을 삭제
    /// - Throws: 삭제 실패 시 에러
    func clear() throws
}
