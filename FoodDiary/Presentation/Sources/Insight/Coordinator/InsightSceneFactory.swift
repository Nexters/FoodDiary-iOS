//
//  InsightSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public protocol InsightSceneProducing {
    func makeInsightScene() -> UIViewController
}

public final class InsightSceneFactory: InsightSceneProducing {
    public typealias UseCase = FetchInsightUseCase<InsightRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>

    private let useCase: UseCase

    public init(useCase: UseCase) {
        self.useCase = useCase
    }

    public func makeInsightScene() -> UIViewController {
        InsightViewController(viewModel: InsightViewModel(fetchInsightUseCase: useCase))
    }
}
