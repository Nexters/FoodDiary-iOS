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

public final class CalendarViewController: UIViewController {
    public enum ViewMode {
        case weekly
        case monthly
    }

    private let weeklyVC: UIViewController
    private let monthlyVC: UIViewController
    private let currentModeSubject = CurrentValueSubject<ViewMode, Never>(.weekly)
    private var currentChild: UIViewController?

    public var currentModePublisher: AnyPublisher<ViewMode, Never> {
        currentModeSubject.eraseToAnyPublisher()
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
        view.backgroundColor = .sdBase
        showViewController(for: currentModeSubject.value)
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
