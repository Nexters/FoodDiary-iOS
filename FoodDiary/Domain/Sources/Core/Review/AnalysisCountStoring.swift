//
//  AnalysisCountStoring.swift
//  Domain
//

import Foundation

public protocol AnalysisCountStoring {
    func getCount() -> Int
    func incrementCount()
    func hasRequestedReview() -> Bool
    func setReviewRequested()
}
