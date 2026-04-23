//
//  AddressSearchCoordinator.swift
//  Presentation
//

import Combine
import Data
import UIKit

public final class AddressSearchCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start(input: AddressSearchSceneInput) {
        guard let presentingVC = navigationController?.topViewController else { return }
        let vc = factories.addressSearch.makeScene(input: input)
        flowBind(vc: vc)
        presentingVC.present(vc, animated: true)
    }
}

// MARK: - Screen Routing

private extension AddressSearchCoordinator {
    func flowBind(vc: AddressSearchViewController) {
        vc.flowPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .finish:
                    self?.finish()
                }
            }
            .store(in: &cancellables)
    }

    func finish() {
        parentCoordinator?.removeChild(self)
    }
}
