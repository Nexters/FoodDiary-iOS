//
//  PrefetchAdjacentMonthsUseCase.swift
//  Domain
//

import Foundation

/// 인접 월 데이터 프리패치 UseCase
public struct PrefetchAdjacentMonthsUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(for date: Date) {
        let calendar = Calendar.current
        let neighbors = [-1, 1].compactMap { calendar.date(byAdding: .month, value: $0, to: date) }
        for neighbor in neighbors {
            Task { await prefetch(neighbor) }
        }
    }

    // MARK: - Private Methods

    private func prefetch(_ date: Date) async {
        let period = Calendar.current.monthlyCalendarPeriod(for: date)
        do {
            _ = try await repository.fetchPhotoURLs(in: period.start...period.end)
        } catch {
            print("Failed to prefetch month \(date): \(error)")
        }
    }
}
