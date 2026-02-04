//
//  MonthlyCalendarHeaderView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

/// 월간 캘린더 상단 헤더 (yyyy년 M월 >)
final class MonthlyCalendarHeaderView: UIView {

    // MARK: - Publishers

    private let monthPickerTapSubject = PassthroughSubject<Void, Never>()
    var monthPickerTapPublisher: AnyPublisher<Void, Never> {
        monthPickerTapSubject.eraseToAnyPublisher()
    }

    // MARK: - UI Components

    private let monthYearLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let chevronButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    private lazy var containerStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [monthYearLabel, chevronButton])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 4
        return sv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerStackView)
    }

    private func setupConstraints() {
        containerStackView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
        }
    }

    private func setupActions() {
        chevronButton.addTarget(self, action: #selector(handleMonthPickerTap), for: .touchUpInside)
    }

    // MARK: - Configuration

    func setMonthYearText(_ text: String) {
        monthYearLabel.setText(text, style: .p18, color: .gray050)
    }

    // MARK: - Actions

    @objc private func handleMonthPickerTap() {
        monthPickerTapSubject.send()
    }
}
