//
//  CalendarViewController.swift
//  Presentation
//
//  Created by 강대훈 on 2/13/26.
//

import Combine
import SnapKit
import UIKit

public final class CalendarViewController: UIViewController {
    private let mainVC: MonthlyCalendarViewController

    private let flowSubject = PassthroughSubject<CalendarFlow, Never>()
    public var flowPublisher: AnyPublisher<CalendarFlow, Never> {
        flowSubject.eraseToAnyPublisher()
    }
    private var cancellables = Set<AnyCancellable>()

    public init(
        mainVC: MonthlyCalendarViewController
    ) {
        self.mainVC = mainVC
        super.init(nibName: nil, bundle: nil)

        mainVC.flowPublisher
            .sink { [weak self] flow in
                self?.flowSubject.send(flow)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .sdBase
        addChild(mainVC)
        view.addSubview(mainVC.view)
        mainVC.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        mainVC.didMove(toParent: self)
    }

    public func addFoodRecord() {
        mainVC.addFoodRecord()
    }
}
