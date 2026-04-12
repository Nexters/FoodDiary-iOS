//
//  DetailCoordinator.swift
//  Presentation
//

import Combine
import UIKit
import Data

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

    public func start(input: DetailSceneInput) {
        let vc = factories.detail.makeScene(input: input)
        vc.hidesBottomBarWhenPushed = true
        flowBind(vc: vc)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Screen Routing

private extension DetailCoordinator {
    func flowBind(vc: DetailViewController<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>, PushNotificationObserver>) {
        vc.flowPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .pushEdit(let input):
                    self?.pushEdit(input: input)
                case .pushImagePicker(let input):
                    self?.pushImagePicker(input: input)
                case .finish:
                    self?.finish()
                }
            }
            .store(in: &cancellables)
    }
}

private extension DetailCoordinator {
    func pushImagePicker(input: ImagePickerSceneInput) {
        let coord = ImagePickerCoordinator(
            factories: factories,
            navigationController: navigationController
        )
        coord.parentCoordinator = self
        addChild(coord)
        coord.start(input: input)
    }

    func pushEdit(input: EditSceneInput) {
        let coord = EditCoordinator(
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
