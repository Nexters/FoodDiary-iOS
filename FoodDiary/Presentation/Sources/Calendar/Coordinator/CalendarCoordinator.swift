//
//  CalendarCoordinator.swift
//  Presentation
//

import UIKit

// MARK: - CalendarCoordinator

public final class CalendarCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?
    public weak var navigationController: UINavigationController?

    private let factories: Factories

    public init(factories: Factories) {
        self.factories = factories
    }

    public func start() {}

    public func configure(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    public func makeViewController() -> CalendarViewController {
        factories.calendar.makeCalendarViewController(
            delegate: self,
            imagePickerDelegate: self
        )
    }
}

// MARK: - CalendarViewControllerDelegate

extension CalendarCoordinator: CalendarViewControllerDelegate {
    public func pushDetail(input: DetailSceneInput) {
        let detailCoordinator = DetailCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        detailCoordinator.parentCoordinator = self
        addChild(detailCoordinator)
        detailCoordinator.start(input: input)
    }
}

// MARK: - ImagePickerDelegate

extension CalendarCoordinator: ImagePickerDelegate {
    public func pushImagePicker(input: ImagePickerSceneInput) {
        let imagePickerCoordinator = ImagePickerCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        imagePickerCoordinator.parentCoordinator = self
        addChild(imagePickerCoordinator)
        imagePickerCoordinator.start(input: input)
    }
}
