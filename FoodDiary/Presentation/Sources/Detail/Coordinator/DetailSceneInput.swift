//
//  DetailSceneInput.swift
//  Presentation
//

import Domain
import Foundation

public struct DetailSceneInput {
    public let date: Date
    public let records: [FoodRecord]
    public let scrollToMealType: MealType?
    public let shouldPopToRoot: Bool
    public let onDismissWithDate: ((Date) -> Void)?

    public init(
        date: Date,
        records: [FoodRecord],
        scrollToMealType: MealType? = nil,
        shouldPopToRoot: Bool = false,
        onDismissWithDate: ((Date) -> Void)? = nil
    ) {
        self.date = date
        self.records = records
        self.scrollToMealType = scrollToMealType
        self.shouldPopToRoot = shouldPopToRoot
        self.onDismissWithDate = onDismissWithDate
    }
}
