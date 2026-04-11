//
//  CalendarCoordinator.swift
//  App
//
//  Created by 강대훈 on 4/11/26.
//

import Presentation
import UIKit

final class CalendarCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: MainCoordinator?

    private let sceneProducer: MainSceneProducer
    private(set) var navigationController: UINavigationController?

    init(sceneProducer: MainSceneProducer) {
        self.sceneProducer = sceneProducer
    }

    func start() {}

    func makeViewController() -> CalendarViewController {
        CalendarViewController(
            weeklyVC: sceneProducer.makeWeeklyCalendarVC(),
            monthlyVC: sceneProducer.makeMonthlyCalendarVC()
        )
    }

    func configure(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
}
