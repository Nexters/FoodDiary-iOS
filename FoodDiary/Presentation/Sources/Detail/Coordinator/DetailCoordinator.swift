//
//  DetailCoordinator.swift
//  Presentation
//

import Combine
import UIKit

public final class DetailCoordinator: Coordinator {
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

    public func start(input: DetailSceneInput) {
        let vc = factories.detail.makeDetailScene(input: input)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
        if let flowVC = vc as? any DetailFlowEmitting {
            flowVC.flowPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] event in
                    switch event {
                    case .pushEdit(let input):
                        self?.pushEdit(input: input)
                    case .pushImagePicker(let input):
                        self?.pushImagePicker(input: input)
                    }
                }
                .store(in: &cancellables)
        }
    }

    private func pushImagePicker(input: ImagePickerSceneInput) {
        let coord = ImagePickerCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }

    private func pushEdit(input: EditSceneInput) {
        let coord = EditCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }
}
