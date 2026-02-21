//
//  PendingFoodRecordRepository.swift
//  Domain
//

import Foundation

/// Pending 음식 기록 저장소 프로토콜
public protocol PendingFoodRecordRepository: Sendable {
    /// 모든 pending 기록 조회
    func fetchAll() async throws -> [PendingFoodRecord]

    /// Pending 기록 저장
    func save(_ record: PendingFoodRecord) async throws

    /// 여러 uploadId의 기록 일괄 삭제
    func delete(byUploadIds uploadIds: [String]) async throws

    /// 특정 날짜의 pending 기록 일괄 삭제
    func delete(byDate date: Date) async throws
}
