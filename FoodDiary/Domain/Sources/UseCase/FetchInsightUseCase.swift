//
//  FetchInsightUseCase.swift
//  Domain
//

import Foundation

public struct FetchInsightUseCase<Repository: InsightRepository> {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute() async throws -> Insight {
        try await repository.fetchInsight()
    }
}
