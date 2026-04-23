//
//  RequestPhotoAuthorizationUseCase.swift
//  Domain
//

import Foundation

public struct RequestPhotoAuthorizationUseCase {
    private let repository: any PhotoAuthorizationRepository

    public init(repository: any PhotoAuthorizationRepository) {
        self.repository = repository
    }

    /// 현재 권한 상태 조회
    public func currentStatus() -> PhotoAuthorizationStatus {
        repository.authorizationStatus()
    }

    /// 권한 요청 (notDetermined 상태일 때만 시스템 다이얼로그 표시)
    /// - Returns: 권한 요청 결과 상태
    public func execute() async -> PhotoAuthorizationStatus {
        await repository.requestAuthorization()
    }

    /// 사진 접근이 허용된 상태인지 확인
    public func isAuthorized() -> Bool {
        let status = currentStatus()
        return status == .authorized || status == .limited
    }
}
