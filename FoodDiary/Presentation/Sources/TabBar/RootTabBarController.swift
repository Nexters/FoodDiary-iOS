//
//  RootTabBarController.swift
//  Presentation
//
//  Created by 강대훈 on 2/13/26.
//

import UIKit
import DesignSystem
import Combine

public final class RootTabBarController: UITabBarController {
    let calendarVC: CalendarViewController
    let insightVC: UIViewController
    private let myPageViewControllerFactory: (@escaping () -> Void) -> UIViewController
    private let didLogoutSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    public var didLogoutPublisher: AnyPublisher<Void, Never> {
        didLogoutSubject.eraseToAnyPublisher()
    }

    public init(
        weeklyVC: UIViewController,
        monthlyVC: UIViewController,
        insightVC: UIViewController,
        myPageViewControllerFactory: @escaping (@escaping () -> Void) -> UIViewController
    ) {
        self.calendarVC = CalendarViewController(weeklyVC: weeklyVC, monthlyVC: monthlyVC)
        self.insightVC = insightVC
        self.myPageViewControllerFactory = myPageViewControllerFactory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupNavigationBar()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setup() {
        self.delegate = self
        tabBar.tintColor = DesignSystemAsset.primary.color

        calendarVC.currentModePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.updateToggleIcon(for: mode)
            }
            .store(in: &cancellables)

        calendarVC.tabBarItem = UITabBarItem(title: "홈", image: DesignSystemAsset.iconHome.image, tag: 0)
        insightVC.tabBarItem = UITabBarItem(title: "인사이트", image: DesignSystemAsset.iconInsight.image, tag: 1)

        let toggleVC = UIViewController()
        toggleVC.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 2)
        toggleVC.tabBarItem.image = DesignSystemAsset.iconWeekly.image

        viewControllers = [calendarVC, insightVC, toggleVC]
    }

    private func setupNavigationBar() {
        let mypageButton = UIBarButtonItem(
            image: DesignSystemAsset.iconMypage.image,
            style: .plain,
            target: self,
            action: #selector(mypageButtonTapped)
        )
        navigationItem.rightBarButtonItem = mypageButton

        let logoImageView = UIImageView(image: DesignSystemAsset.iconNavLogo.image)
        logoImageView.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoImageView)
    }

    @objc private func mypageButtonTapped() {
        let myPageVC = myPageViewControllerFactory { [weak self] in
            self?.didLogoutSubject.send()
        }
        myPageVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(myPageVC, animated: true)
    }
    
    private func toggleViewMode() {
        calendarVC.toggleViewMode()
    }
    
    private func updateToggleIcon(for mode: CalendarViewController.ViewMode) {
        guard let items = tabBar.items, items.count > 2 else { return }
        
        let newImage = mode == .monthly ? DesignSystemAsset.iconWeekly.image : DesignSystemAsset.iconMonthly.image
        items[2].image = newImage
    }
}

extension RootTabBarController: UITabBarControllerDelegate {
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let index = viewControllers?.firstIndex(of: viewController) else { return true }
        
        if index == 2 {
            toggleViewMode()
            return false
        }
        
        return true
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        for subview in self.tabBar.subviews {
            if subview.frame.origin.x > self.tabBar.bounds.width * 0.6 {
                subview.isHidden = selectedIndex == 1
            }
        }
    }
}
