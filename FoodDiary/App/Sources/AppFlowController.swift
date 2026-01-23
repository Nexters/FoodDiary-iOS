//
//  AppFlowController.swift
//  App
//
//  Created by 강대훈 on 1/23/26.
//

import UIKit
import Presentation
import Domain
import Data

final class AppFlowController: UIViewController {
    private var isLogin: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        routeToAppropriateScreen()
    }

    private func routeToAppropriateScreen() {
        let destinationViewController = isLogin ? MainViewController() : LoginViewController()

        addChild(destinationViewController)
        view.addSubview(destinationViewController.view)
        destinationViewController.view.frame = view.bounds
        destinationViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        destinationViewController.didMove(toParent: self)
    }
}
