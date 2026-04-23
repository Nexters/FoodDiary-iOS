//
//  AnalysisCountStorage.swift
//  Data
//

import Domain
import Foundation

public struct AnalysisCountStorage: AnalysisCountStoring {
    private let countKey = "analysis_push_count"
    private let reviewRequestedKey = "app_review_requested"

    public init() {}

    public func getCount() -> Int {
        UserDefaults.standard.integer(forKey: countKey)
    }

    public func incrementCount() {
        let current = getCount()
        UserDefaults.standard.set(current + 1, forKey: countKey)
    }

    public func hasRequestedReview() -> Bool {
        UserDefaults.standard.bool(forKey: reviewRequestedKey)
    }

    public func setReviewRequested() {
        UserDefaults.standard.set(true, forKey: reviewRequestedKey)
    }
}
