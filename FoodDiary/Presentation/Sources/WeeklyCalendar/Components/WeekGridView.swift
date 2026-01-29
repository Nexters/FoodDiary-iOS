//
//  WeekGridView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

/// 7일 그리드 뷰
final class WeekGridView: UIView {

    // MARK: - Publisher

    var dateTapPublisher: AnyPublisher<Date, Never> {
        dateTapSubject.eraseToAnyPublisher()
    }

    private let dateTapSubject = PassthroughSubject<Date, Never>()

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        view.layer.cornerRadius = 16
        return view
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 4
        return sv
    }()

    private var dayCells: [DayCellView] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(stackView)

        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }

        // 7개의 DayCell 생성
        (0..<7).forEach { _ in
            let cell = DayCellView()
            cell.tapHandler = { [weak self] date in
                self?.dateTapSubject.send(date)
            }
            dayCells.append(cell)
            stackView.addArrangedSubview(cell)
        }
    }

    // MARK: - Public Methods

    func configure(with days: [WeeklyCalendarDay], selectedDate: Date) {
        guard days.count == 7 else { return }
        let calendar = Calendar.current

        zip(dayCells, days).forEach { cell, dayData in
            let isSelected = calendar.isDate(selectedDate, inSameDayAs: dayData.date)
            cell.configure(with: dayData, isSelected: isSelected)
        }
    }
}
