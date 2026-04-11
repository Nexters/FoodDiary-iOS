//
//  InsightCoordinator.swift
//  Presentation
//

import UIKit

public final class InsightCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factory: any InsightSceneProducing

    public init(factory: any InsightSceneProducing) {
        self.factory = factory
    }

    public func start() {}

    public func makeViewController() -> UIViewController {
        factory.makeInsightScene()
    }
}
