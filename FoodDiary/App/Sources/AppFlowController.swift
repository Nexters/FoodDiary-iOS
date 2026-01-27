//
//  AppFlowController.swift
//  App
//
//  Created by 강대훈 on 1/23/26.
//

import Combine
import UIKit
import DI
import Presentation
import Domain
import Data

final class AppFlowController: UIViewController {
    private var isLogin: Bool = false
    private var currentChild: UIViewController?
    private var cancellables = Set<AnyCancellable>()
    private let container: DIContainer
    
    public init(container: DIContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        do {
            let mainVC = try container.resolve(MainViewController.self)
            return mainVC
        } catch {
            print(error.localizedDescription)
            return UIViewController()
        }
    }
    
    func createLoginView() -> UIViewController {
        do {
            let loginVC = try container.resolve(LoginViewController.self)
            
            loginVC.didLoginPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.handleLoginSuccess()
                }
                .store(in: &cancellables)
            
            return loginVC
        } catch {
            print(error.localizedDescription)
            return UIViewController()
        }
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
