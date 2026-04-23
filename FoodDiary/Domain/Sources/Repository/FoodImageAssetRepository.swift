//
//  FoodImageAssetRepository.swift
//  Domain
//
//  Created by Kai Lee on 1/23/26.
//

import Foundation

public protocol FoodImageAssetRepository: Sendable {
    /// 날짜별 음식 사진 조회 (음식 확률 순 정렬)
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (필수)
    ///   - endDate: 조회 종료 날짜 (nil이면 현재까지)
    /// - Returns: 날짜별로 그룹화된 음식 사진 딕셔너리
    func fetchFoodImageAssets(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodImageAsset]]

    /// 현재 주 + 과거 N주 범위의 사진 데이터를 백그라운드에서 미리 로드하여 캐시 워밍
    /// - Parameters:
    ///   - weekCount: 과거 몇 주를 prefetch할지
    ///   - date: 기준 날짜
    func prefetchFoodImageAssets(forPreviousWeeks weekCount: Int, of date: Date)
}
