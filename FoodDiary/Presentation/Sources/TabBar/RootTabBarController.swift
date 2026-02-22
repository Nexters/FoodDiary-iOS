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
    private var cancellables = Set<AnyCancellable>()

    public var didLogoutPublisher: AnyPublisher<Void, Never> {
        calendarVC.didLogoutPublisher
    }

    public init(weeklyVC: UIViewController, monthlyVC: UIViewController, insightVC: UIViewController) {
        self.calendarVC = CalendarViewController(weeklyVC: weeklyVC, monthlyVC: monthlyVC)
        self.insightVC = insightVC
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
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

        let calendarNav = UINavigationController(rootViewController: calendarVC)
        calendarNav.tabBarItem = UITabBarItem(title: "홈", image: DesignSystemAsset.iconHome.image, tag: 0)

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .sdBase
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.shadowColor = .clear
        
        calendarNav.navigationBar.standardAppearance = navAppearance
        calendarNav.navigationBar.scrollEdgeAppearance = navAppearance
        calendarNav.navigationBar.tintColor = .white

        let insightNav = UINavigationController(rootViewController: insightVC)
        insightNav.tabBarItem = UITabBarItem(title: "인사이트", image: DesignSystemAsset.iconInsight.image, tag: 1)

        let toggleVC = UIViewController()
        toggleVC.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 2)
        toggleVC.tabBarItem.image = DesignSystemAsset.iconWeekly.image

        viewControllers = [calendarNav, insightNav, toggleVC]
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
