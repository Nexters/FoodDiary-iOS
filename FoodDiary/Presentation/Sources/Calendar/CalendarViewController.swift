//
//  CalendarViewController.swift
//  Presentation
//
//  Created by 강대훈 on 2/13/26.
//

import Combine
import DesignSystem
import SnapKit
import UIKit

public final class CalendarViewController: UIViewController {
    public enum ViewMode {
        case weekly
        case monthly
    }

    private let weeklyVC: UIViewController
    private let monthlyVC: UIViewController
    private let currentModeSubject = CurrentValueSubject<ViewMode, Never>(.weekly)
    private var currentChild: UIViewController?

    private let flowSubject = PassthroughSubject<CalendarFlow, Never>()
    public var flowPublisher: AnyPublisher<CalendarFlow, Never> {
        flowSubject.eraseToAnyPublisher()
    }
    private var cancellables = Set<AnyCancellable>()

    public var currentModePublisher: AnyPublisher<ViewMode, Never> {
        currentModeSubject.eraseToAnyPublisher()
    }

    public init(
        weeklyVC: UIViewController,
        monthlyVC: UIViewController,
        weeklyFlowPublisher: AnyPublisher<CalendarFlow, Never>,
        monthlyFlowPublisher: AnyPublisher<CalendarFlow, Never>
    ) {
        self.weeklyVC = weeklyVC
        self.monthlyVC = monthlyVC
        super.init(nibName: nil, bundle: nil)

        Publishers.Merge(weeklyFlowPublisher, monthlyFlowPublisher)
            .sink { [weak self] flow in self?.flowSubject.send(flow) }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
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

        // 초기 로드: 애니메이션 없이 바로 추가
        guard let outgoingVC = currentChild else {
            addChild(targetVC)
            view.addSubview(targetVC.view)
            targetVC.view.snp.makeConstraints { $0.edges.equalToSuperview() }
            targetVC.didMove(toParent: self)
            currentChild = targetVC
            return
        }

        addChild(targetVC)
        targetVC.view.alpha = 0
        view.addSubview(targetVC.view)
        targetVC.view.snp.makeConstraints { $0.edges.equalToSuperview() }

        UIView.animate(withDuration: 0.4) {
            targetVC.view.alpha = 1
            outgoingVC.view.alpha = 0
        } completion: { _ in
            outgoingVC.view.alpha = 1
            outgoingVC.willMove(toParent: nil)
            outgoingVC.view.removeFromSuperview()
            outgoingVC.removeFromParent()
            targetVC.didMove(toParent: self)
            self.currentChild = targetVC
        }
    }
}
