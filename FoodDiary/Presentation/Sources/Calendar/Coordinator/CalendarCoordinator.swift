//
//  CalendarCoordinator.swift
//  Presentation
//

import Combine
import UIKit

// MARK: - CalendarCoordinator

public final class CalendarCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?
    public weak var navigationController: UINavigationController?

    private let factories: Factories
    private var cancellables = Set<AnyCancellable>()

    public init(factories: Factories) {
        self.factories = factories
    }

    public func start() {}

    public func configure(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    public func makeViewController() -> CalendarViewController {
        let calendarVC = factories.calendar.makeScene()
        calendarVC.flowPublisher
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
        return calendarVC
    }

    private func pushDetail(input: DetailSceneInput) {
        let detailCoordinator = DetailCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        detailCoordinator.parentCoordinator = self
        addChild(detailCoordinator)
        detailCoordinator.start(input: input)
    }

    private func pushImagePicker(input: ImagePickerSceneInput) {
        let imagePickerCoordinator = ImagePickerCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        imagePickerCoordinator.parentCoordinator = self
        addChild(imagePickerCoordinator)
        imagePickerCoordinator.start(input: input)
    }
}
