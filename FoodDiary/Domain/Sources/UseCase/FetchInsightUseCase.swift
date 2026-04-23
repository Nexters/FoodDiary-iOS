//
//  FetchInsightUseCase.swift
//  Domain
//

import Foundation

public struct FetchInsightUseCase {
    private let repository: any InsightRepository

    public init(repository: any InsightRepository) {
        self.repository = repository
    }

    public func execute() async throws -> Insight {
        try await repository.fetchInsight()
    }
}
