//
//  InsightSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public final class InsightSceneFactory {
    public typealias UseCase = FetchInsightUseCase<InsightRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>

    private let useCase: UseCase

    public init(useCase: UseCase) {
        self.useCase = useCase
    }

    public func makeInsightScene() -> InsightViewController<InsightRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>> {
        InsightViewController(viewModel: InsightViewModel(fetchInsightUseCase: useCase))
    }
}
