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
        button.setImage(DesignSystemAsset.iconNext.image, for: .normal)
        button.tintColor = .white
        return button
    }()

    private lazy var containerStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [monthYearLabel, chevronButton])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 4
        sv.isUserInteractionEnabled = false
        return sv
    }()

    private lazy var tapButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        return button
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
        addSubview(tapButton)
    }

    private func setupConstraints() {
        snp.makeConstraints {
            $0.height.equalTo(44)
        }

        containerStackView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        chevronButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }

        tapButton.snp.makeConstraints {
            $0.edges.equalTo(containerStackView)
        }
    }

    private func setupActions() {
        tapButton.addTarget(self, action: #selector(handleMonthPickerTap), for: .touchUpInside)
    }

    // MARK: - Configuration

    func setMonthYearText(_ text: String) {
        monthYearLabel.setText(text, style: .p18, color: .gray050)
    }

    func resetChevron() {
        UIView.transition(
            with: chevronButton,
            duration: 0.3,
            options: .transitionFlipFromBottom,
            animations: {
                self.chevronButton.setImage(DesignSystemAsset.iconNext.image, for: .normal)
            }
        )
    }

    // MARK: - Actions

    @objc private func handleMonthPickerTap() {
        UIView.transition(
            with: chevronButton,
            duration: 0.3,
            options: .transitionFlipFromTop,
            animations: {
                self.chevronButton.setImage(DesignSystemAsset.iconDown.image, for: .normal)
            }
        )
        monthPickerTapSubject.send()
    }
}
