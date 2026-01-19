//
//  FetchPhotosByDateUseCase.swift
//  Domain
//
//  Created by Kai Lee on 1/19/26.
//

import Core
import Foundation

public struct FetchPhotosByDateUseCase {
    private let photoLibrary: PhotoLibraryRepresentable

    public init(photoLibrary: PhotoLibraryRepresentable) {
        self.photoLibrary = photoLibrary
    }

    /// 날짜 범위에 해당하는 사진을 날짜별로 그룹화하여 조회
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (필수)
    ///   - endDate: 조회 종료 날짜 (nil이면 현재까지)
    /// - Returns: 날짜별로 그룹화된 사진 섹션 배열 (최신순)
    public func execute(
        from startDate: Date,
        to endDate: Date? = nil
    ) async throws -> [PhotoSection] {
        try await photoLibrary.fetchPhotosByDate(from: startDate, to: endDate)
    }
}
