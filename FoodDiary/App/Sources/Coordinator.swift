//
//  Coordinator.swift
//  App
//
//  Created by 강대훈 on 4/8/26.
//

import Foundation
import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
}

extension Coordinator {
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}

protocol SceneTransitioning: AnyObject {
    func transition(to viewController: UIViewController)
}
