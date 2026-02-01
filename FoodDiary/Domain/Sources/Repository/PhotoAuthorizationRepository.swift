//
//  PhotoAuthorizationRepository.swift
//  Domain
//
//  Created by Kai Lee on 2/1/26.
//

import Foundation

/// 사진 라이브러리 권한 상태
public enum PhotoAuthorizationStatus: Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case limited
}

/// 사진 라이브러리 권한 관리 Repository
public protocol PhotoAuthorizationRepository: Sendable {
    /// 현재 사진 라이브러리 권한 상태 조회
    func authorizationStatus() -> PhotoAuthorizationStatus

    /// 사진 라이브러리 권한 요청
    /// - Returns: 권한 요청 결과
    func requestAuthorization() async -> PhotoAuthorizationStatus
}
