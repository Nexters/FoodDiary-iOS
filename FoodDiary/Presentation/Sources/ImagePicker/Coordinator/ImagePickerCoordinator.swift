//
//  ImagePickerCoordinator.swift
//  Presentation
//

import Combine
import Data
import Domain
import Photos
import UIKit

// MARK: - Coordinator

public final class ImagePickerCoordinator: Coordinator {
    public var childCoordinators: [any Coordinator] = []
    public weak var parentCoordinator: (any Coordinator)?

    private let factories: Factories
    private weak var navigationController: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    public init(factories: Factories, navigationController: UINavigationController?) {
        self.factories = factories
        self.navigationController = navigationController
    }

    public func start(input: ImagePickerSceneInput) {
        let vc = factories.imagePicker.makeScene(input: input)
        flowBind(vc: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Screen Routing

private extension ImagePickerCoordinator {
    func flowBind(vc: ImagePickerViewController) {
        vc.resultPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.finish()
            }
            .store(in: &cancellables)
    }

    func finish() {
        parentCoordinator?.removeChild(self)
    }
}
