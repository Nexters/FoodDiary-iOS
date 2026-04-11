//
//  DefaultViewTransitionHandler.swift
//  Presentation
//

import SnapKit
import UIKit

public final class DefaultViewTransitionHandler: ViewTransitionHandling {
    private weak var currentChild: UIViewController?

    public init() {}

    public func transition(from parent: UIViewController, to viewController: UIViewController) {
        let previousChild = currentChild

        parent.addChild(viewController)
        parent.view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        viewController.view.alpha = 0

        UIView.animate(
            withDuration: 0.3,
            animations: {
                previousChild?.view.alpha = 0
                viewController.view.alpha = 1
            },
            completion: { _ in
                previousChild?.willMove(toParent: nil)
                previousChild?.view.removeFromSuperview()
                previousChild?.removeFromParent()

                viewController.didMove(toParent: parent)
                self.currentChild = viewController
            }
        )
    }
}
