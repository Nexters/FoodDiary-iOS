//
//  CalendarViewController.swift
//  Presentation
//
//  Created by 강대훈 on 2/13/26.
//

import UIKit
import Combine
import DesignSystem
import SnapKit
import DI

public final class CalendarViewController: UIViewController {
    public enum ViewMode {
        case weekly
        case monthly
    }

    private let weeklyVC: UIViewController
    private let monthlyVC: UIViewController
    private let currentModeSubject = CurrentValueSubject<ViewMode, Never>(.weekly)
    private let didLogoutSubject = PassthroughSubject<Void, Never>()
    private var currentChild: UIViewController?
    private var myPageCancellable: AnyCancellable?

    public var currentModePublisher: AnyPublisher<ViewMode, Never> {
        currentModeSubject.eraseToAnyPublisher()
    }

    public var didLogoutPublisher: AnyPublisher<Void, Never> {
        didLogoutSubject.eraseToAnyPublisher()
    }

    public init(weeklyVC: UIViewController, monthlyVC: UIViewController) {
        self.weeklyVC = weeklyVC
        self.monthlyVC = monthlyVC
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        showViewController(for: currentModeSubject.value)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        guard let myPageVM = try? DIContainer.shared.resolve(MyPageViewModel.self) else {
            print("MyPageViewModel resolve 실패")
            return
        }

        let myPageVC = MyPageViewController(viewModel: myPageVM)
        myPageVC.hidesBottomBarWhenPushed = true

        myPageCancellable = myPageVC.didLogoutPublisher
            .sink { [weak self] in
                self?.didLogoutSubject.send()
            }

        navigationController?.pushViewController(myPageVC, animated: true)
    }

    public func toggleViewMode() {
        let newMode: ViewMode = currentModeSubject.value == .weekly ? .monthly : .weekly
        currentModeSubject.send(newMode)
        showViewController(for: newMode)
    }

    private func showViewController(for mode: ViewMode) {
        let targetVC = mode == .weekly ? weeklyVC : monthlyVC

        if let currentChild {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }
        
        addChild(targetVC)
        view.addSubview(targetVC.view)
        targetVC.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        targetVC.didMove(toParent: self)

        currentChild = targetVC
    }
}
