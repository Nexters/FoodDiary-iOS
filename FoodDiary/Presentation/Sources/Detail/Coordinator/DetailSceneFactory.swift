//
//  DetailSceneFactory.swift
//  Presentation
//

import Data
import DI
import Domain
import UIKit

public protocol DetailSceneProducing {
    func makeDetailScene(input: DetailSceneInput) -> UIViewController
}

public final class DetailSceneFactory: DetailSceneProducing {
    private typealias DetailVM = DetailViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
        PushNotificationObserver
    >

    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
    }

    public func makeDetailScene(input: DetailSceneInput) -> UIViewController {
        guard let detailVM = try? container.resolve(DetailVM.self, argument: (input.date, input.records)) else {
            fatalError("DetailViewModel not registered")
        }
        return DetailViewController(
            viewModel: detailVM,
            initialScrollTarget: input.scrollToMealType,
            shouldPopToRoot: input.shouldPopToRoot,
            onDismissWithDate: input.onDismissWithDate
        )
    }
}
