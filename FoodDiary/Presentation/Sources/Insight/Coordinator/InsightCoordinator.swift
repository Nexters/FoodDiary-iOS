//
//  InsightCoordinator.swift
//  Presentation
//

import UIKit

public final class InsightCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories

    public init(factories: Factories) {
        self.factories = factories
    }

    public func start() {}

    public func makeViewController() -> UIViewController {
        factories.insight.makeInsightScene()
    }
}
