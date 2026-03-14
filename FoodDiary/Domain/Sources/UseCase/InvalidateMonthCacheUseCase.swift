//
//  InvalidateMonthCacheUseCase.swift
//  Domain
//

import Foundation

/// 월간 캘린더 캐시 무효화 UseCase
public struct InvalidateMonthCacheUseCase<Repository: FoodRecordRepository>: Sendable {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public func execute(for date: Date) {
        let period = Calendar.current.monthlyCalendarPeriod(for: date)
        repository.invalidatePhotoURLCache(in: period.start...period.end)
    }
}
