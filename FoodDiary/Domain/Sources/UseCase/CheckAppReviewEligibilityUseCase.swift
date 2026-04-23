//
//  CheckAppReviewEligibilityUseCase.swift
//  Domain
//

import Foundation

public struct CheckAppReviewEligibilityUseCase {
    private let analysisCountStorage: AnalysisCountStoring
    private let requiredCount: Int

    public init(
        analysisCountStorage: AnalysisCountStoring,
        requiredCount: Int = 2
    ) {
        self.analysisCountStorage = analysisCountStorage
        self.requiredCount = requiredCount
    }

    /// 카운트를 증가시키고, 리뷰 요청 조건 충족 여부를 반환
    public func execute() -> Bool {
        guard !analysisCountStorage.hasRequestedReview() else { return false }
        analysisCountStorage.incrementCount()
        if analysisCountStorage.getCount() >= requiredCount {
            analysisCountStorage.setReviewRequested()
            return true
        }
        return false
    }
}
