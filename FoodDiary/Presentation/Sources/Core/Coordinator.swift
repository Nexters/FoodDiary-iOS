//
//  Coordinator.swift
//  Presentation
//

import UIKit

public protocol Coordinator: AnyObject {
    var childCoordinators: [any Coordinator] { get set }
}

public extension Coordinator {
    func addChild(_ coordinator: any Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: any Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}

public protocol SceneTransitioning: AnyObject {
    func transition(to viewController: UIViewController)
}
