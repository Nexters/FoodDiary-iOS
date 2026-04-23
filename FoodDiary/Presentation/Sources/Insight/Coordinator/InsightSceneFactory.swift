//
//  InsightSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public final class InsightSceneFactory {
    private let useCase: FetchInsightUseCase

    public init(useCase: FetchInsightUseCase) {
        self.useCase = useCase
    }

    public func makeScene() -> InsightViewController {
        InsightViewController(viewModel: InsightViewModel(fetchInsightUseCase: useCase))
    }
}
