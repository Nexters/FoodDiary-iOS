//
//  AppFlowController.swift
//  App
//
//  Created by 강대훈 on 1/23/26.
//

import Combine
import UIKit
import Presentation
import Domain
import Data

final class AppFlowController: UIViewController {
    private var isLogin: Bool = false
    private var currentChild: UIViewController?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        routeToAppropriateScreen()
    }
}

private extension AppFlowController {
    func routeToAppropriateScreen() {
        let destinationVC = isLogin ? createMainView() : createLoginView()
        transition(to: destinationVC)
    }
    
    func createMainView() -> UIViewController {
        return MainViewController()
    }
    
    func createLoginView() -> UIViewController {
        let loginVC = LoginViewController()
        
        loginVC.didLogin
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleLoginSuccess()
            }
            .store(in: &cancellables)
        
        return loginVC
    }
    
    func handleLoginSuccess() {
        isLogin = true
        routeToAppropriateScreen()
    }
    
    func transition(to viewController: UIViewController) {
        if let currentChild {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }

        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)

        currentChild = viewController
    }
}
