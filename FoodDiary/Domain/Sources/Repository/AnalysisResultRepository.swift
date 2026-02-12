//
//  AnalysisResultRepository.swift
//  Domain
//

import Foundation

/// 분석 결과 상태
public enum AnalysisStatus: Sendable, Equatable {
    case pending
    case completed(FoodRecord)
    case failed(reason: String)
}

/// 분석 결과 조회 Repository 프로토콜
public protocol AnalysisResultRepository: Sendable {

    /// 업로드 ID 목록에 대한 분석 상태 조회
    ///  - returns: 업로드 ID별 분석 상태 딕셔너리
    func fetchResults(for uploadIds: [String]) async throws -> [String: AnalysisStatus]
}
