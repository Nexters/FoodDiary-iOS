//
//  FoodPhotoAlbumRepository.swift
//  Domain
//
//  Created by Kai Lee on 1/23/26.
//

import Foundation

public protocol FoodPhotoRepository: Sendable {
    associatedtype Asset: ImageAssetable
    
    /// 날짜별 음식 사진 조회 (음식 확률 순 정렬)
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (필수)
    ///   - endDate: 조회 종료 날짜 (nil이면 현재까지)
    /// - Returns: 날짜별로 그룹화된 음식 사진 딕셔너리
    func fetchFoodPhotos(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [Date: [FoodPhoto<Asset>]]
}
