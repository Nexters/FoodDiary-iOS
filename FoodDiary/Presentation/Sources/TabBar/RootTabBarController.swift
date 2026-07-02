//
//  RootTabBarController.swift
//  Presentation
//
//  Created by 강대훈 on 2/13/26.
//

import Combine
import DesignSystem
import UIKit

public final class RootTabBarController: UITabBarController {
    let calendarVC: CalendarViewController
    let insightVC: UIViewController
    private let mypageButtonTapSubject = PassthroughSubject<Void, Never>()

    public var mypageButtonTapPublisher: AnyPublisher<Void, Never> {
        mypageButtonTapSubject.eraseToAnyPublisher()
    }

    public init(
        calendarVC: CalendarViewController,
        insightVC: UIViewController
    ) {
        self.calendarVC = calendarVC
        self.insightVC = insightVC
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
        tabBar.isHidden = false
        tabBar.tintColor = DesignSystemAsset.primary.color
        tabBar.isTranslucent = true
        tabBar.backgroundColor = .clear
        tabBar.barTintColor = .clear
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.layer.backgroundColor = UIColor.clear.cgColor

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray600]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: DesignSystemAsset.primary.color]
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray600]
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: DesignSystemAsset.primary.color]
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray600]
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: DesignSystemAsset.primary.color]
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        calendarVC.tabBarItem = UITabBarItem(title: "홈", image: DesignSystemAsset.iconHome.image, tag: 0)
        insightVC.tabBarItem = UITabBarItem(title: "인사이트", image: DesignSystemAsset.iconInsight.image, tag: 1)

        let addVC = UIViewController()
        let addItem = UITabBarItem(tabBarSystemItem: .search, tag: 2)
        let addImage = UIImage(systemName: "plus")?
            .withTintColor(DesignSystemAsset.primary.color, renderingMode: .alwaysOriginal)
        addItem.image = addImage
        addItem.selectedImage = addImage
        addItem.title = nil
        addItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        addItem.accessibilityLabel = "음식 기록 추가"
        addVC.tabBarItem = addItem

        viewControllers = [calendarVC, insightVC, addVC]
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
        mypageButtonTapSubject.send()
    }
}

extension RootTabBarController: UITabBarControllerDelegate {
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let index = viewControllers?.firstIndex(of: viewController) else { return true }

        if index == 2 {
            calendarVC.addFoodRecord()
            return false
        }

        return true
    }

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    }
}
