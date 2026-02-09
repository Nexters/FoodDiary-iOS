//
//  MockAnalysisResultRepository.swift
//  Data
//

import Domain
import Foundation

/// Mock 분석 결과 Repository (서버 API 완성 전 사용)
public final class MockAnalysisResultRepository: AnalysisResultRepository, @unchecked Sendable {

    public init() {}

    public func fetchResults(for uploadIds: [String]) async throws -> [String: AnalysisStatus] {
        // TODO: 실제 API 구현 시 교체
        // 현재는 모든 요청에 대해 pending 상태 반환
        var results: [String: AnalysisStatus] = [:]
        for uploadId in uploadIds {
            results[uploadId] = .pending
        }
        return results
    }
}
