//
//  EditCoordinator.swift
//  Presentation
//

import Combine
import UIKit
import Data

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

    public func start(input: EditSceneInput) {
        let vc = factories.edit.makeScene(input: input)
        flowBind(vc: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Screen Routing

private extension EditCoordinator {
    func flowBind(vc: EditFoodRecordViewController) {
        vc.flowPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .presentAddressSearch(let input):
                    self?.presentAddressSearch(input: input)
                case .finish:
                    self?.finish()
                }
            }
            .store(in: &cancellables)
    }
}

private extension EditCoordinator {
    func presentAddressSearch(input: AddressSearchSceneInput) {
        let coord = AddressSearchCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }
    
    func finish() {
        parentCoordinator?.removeChild(self)
    }
}
