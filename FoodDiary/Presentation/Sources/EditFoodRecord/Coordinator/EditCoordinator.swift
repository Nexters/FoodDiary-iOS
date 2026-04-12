//
//  EditCoordinator.swift
//  Presentation
//

import Combine
import UIKit

// MARK: - Coordinator

public final class EditCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start() {}

    public func start(input: EditSceneInput) {
        guard let nav = navigationController else { return }
        let vc = factories.edit.makeScene(input: input)
        nav.pushViewController(vc, animated: true)
        if let flowVC = vc as? any EditFlowEmitting {
            flowVC.flowPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] event in
                    switch event {
                    case .presentAddressSearch(let input):
                        self?.presentAddressSearch(input: input)
                    }
                }
                .store(in: &cancellables)
        }
    }

    private func presentAddressSearch(input: AddressSearchSceneInput) {
        let coord = AddressSearchCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }
}
