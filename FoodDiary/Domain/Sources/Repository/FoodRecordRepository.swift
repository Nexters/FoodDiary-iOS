//
//  FoodRecordRepository.swift
//  Domain
//

import Foundation

/// 음식 기록 Repository 프로토콜 (서버 API)
public protocol FoodRecordRepository: Sendable {
    /// 특정 날짜 범위 내의 사진 URL 조회
    /// - Parameter dateRange: 조회할 날짜 범위
    /// - Returns: 날짜별 기록된 이미지 URL
    func fetchPhotoURLs(in dateRange: ClosedRange<Date>) async throws -> [Date: [URL]]
    
    /// 특정 날짜 범위 내의 기록 조회
    /// - Parameter dateRange: 조회할 날짜 범위
    /// - Returns: 날짜별 기록 딕셔너리
    func fetchRecords(in dateRange: ClosedRange<Date>) async throws -> [Date: [FoodRecord]]

    /// 특정 날짜의 기록 조회
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 음식 기록 배열
    func fetchRecords(for date: Date) async throws -> [FoodRecord]

    /// 음식 기록 업로드 (서버 업로드 → 업로드 ID 반환, AI 분석은 비동기로 진행)
    /// - Parameter request: 생성 요청 데이터
    /// - Returns: 서버에서 발급한 업로드 ID (Remote Push로 분석 결과 수신 시 매칭용)
    func uploadRecord(_ request: CreateFoodRecordRequest) async throws -> String

    /// 음식 기록 수정
    /// - Parameter request: 수정 요청 데이터
    /// - Returns: 수정된 FoodRecord
    func updateRecord(_ request: UpdateFoodRecordRequest) async throws -> FoodRecord

    /// 음식 기록 삭제
    /// - Parameter id: 삭제할 기록 ID
    func deleteRecord(id: String) async throws
}
