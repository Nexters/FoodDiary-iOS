//
//  FoodRecordRepository.swift
//  Domain
//

import Foundation

/// 음식 기록 조회 Repository 프로토콜 (서버 API)
public protocol FoodRecordRepository: Sendable {
    /// 특정 날짜 범위 내의 기록된 날짜들 조회
    /// - Parameter dateRange: 조회할 날짜 범위
    /// - Returns: 기록이 있는 날짜들의 집합 (startOfDay 기준)
    func fetchRecordedDates(in dateRange: ClosedRange<Date>) async throws -> Set<Date>

    /// 특정 날짜의 기록 조회
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 음식 기록 배열
    func fetchRecords(for date: Date) async throws -> [FoodRecord]
}
