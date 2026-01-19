//
//  PhotoLibraryRepresentable.swift
//  Core
//
//  Created by Kai Lee on 1/19/26.
//

import Photos

public protocol PhotoLibraryRepresentable: Sendable {
    /// 사진 라이브러리 접근 권한 요청
    func requestAuthorization() async -> PHAuthorizationStatus

    /// 날짜별 사진 조회 (최신순)
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (필수)
    ///   - endDate: 조회 종료 날짜 (nil이면 현재까지)
    /// - Returns: 날짜별로 그룹화된 사진 섹션 배열
    func fetchPhotosByDate(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [PhotoSection]
}
