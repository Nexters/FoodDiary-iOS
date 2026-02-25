//
//  FoodImageAssetRepository.swift
//  Domain
//
//  Created by Kai Lee on 1/23/26.
//

import Foundation

public protocol FoodImageAssetRepository: Sendable {
    associatedtype Asset: ImageAssetable

    /// 날짜별 음식 사진 조회 (음식 확률 순 정렬)
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (필수)
    ///   - endDate: 조회 종료 날짜 (nil이면 현재까지)
    /// - Returns: 날짜별로 그룹화된 음식 사진 딕셔너리
    func fetchFoodImageAssets(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodImageAsset<Asset>]]

    /// 인접 주간 사진 데이터를 미리 로드하여 캐시 워밍 (이전 주 + 현재 주 + 다음 주)
    /// - Parameter date: 기준 날짜
    func prefetchFoodImageAssets(forAdjacentWeeksOf date: Date)
}
