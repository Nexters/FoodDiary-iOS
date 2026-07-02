//
//  CalendarCoordinator.swift
//  Presentation
//

import Combine
import UIKit

public final class CalendarCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    public weak var navigationController: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    public init(factories: Factories) {
        self.factories = factories
    }

    public func configure(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    public func makeViewController() -> MonthlyCalendarViewController {
        let calendarVC = factories.calendar.makeScene()
        flowBind(vc: calendarVC)
        return calendarVC
    }
}

// MARK: - Screen Routing

private extension CalendarCoordinator {
    func flowBind(vc: MonthlyCalendarViewController) {
        vc.flowPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .pushDetail(let input):
                    self?.pushDetail(input: input)
                case .pushImagePicker(let input):
                    self?.pushImagePicker(input: input)
                }
            }
            .store(in: &cancellables)
    }
}

private extension CalendarCoordinator {
    func pushDetail(input: DetailSceneInput) {
        let coord = DetailCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }
    
    func pushImagePicker(input: ImagePickerSceneInput) {
        let coord = ImagePickerCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }
}
