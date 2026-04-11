//
//  CalendarCoordinator.swift
//  Presentation
//

import UIKit

public final class CalendarCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factory: any CalendarSceneProducing
    public private(set) var navigationController: UINavigationController?

    public init(factory: any CalendarSceneProducing) {
        self.factory = factory
    }

    public func start() {}

    public func makeViewController() -> CalendarViewController {
        CalendarViewController(
            weeklyVC: factory.makeWeeklyCalendarVC(),
            monthlyVC: factory.makeMonthlyCalendarVC()
        )
    }
}
