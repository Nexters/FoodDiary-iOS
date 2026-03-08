//
//  InsightRepository.swift
//  Domain
//

import Foundation

public protocol InsightRepository {
    func fetchInsight() async throws -> Insight
}
