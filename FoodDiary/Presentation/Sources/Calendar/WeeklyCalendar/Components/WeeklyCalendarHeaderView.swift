//
//  WeeklyCalendarHeaderView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

/// 주간 캘린더 상단 헤더 (월 표시 + 좌우 네비게이션)
final class WeeklyCalendarHeaderView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let headerHeight: CGFloat = 44
        static let navigationSpacing: CGFloat = 8
        static let buttonSize: CGFloat = 44
    }

    // MARK: - Publishers

    var previousTapPublisher: AnyPublisher<Void, Never> {
        previousTapSubject.eraseToAnyPublisher()
    }

    var nextTapPublisher: AnyPublisher<Void, Never> {
        nextTapSubject.eraseToAnyPublisher()
    }

    private let previousTapSubject = PassthroughSubject<Void, Never>()
    private let nextTapSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Components

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()

    private let previousButton: UIButton = {
        let button = UIButton()
        button.setImage(DesignSystemAsset.iconNext.image.withHorizontallyFlippedOrientation(), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton()
        button.setImage(DesignSystemAsset.iconNext.image, for: .normal)
        button.tintColor = .white
        return button
    }()

    private let navigationStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = Constants.navigationSpacing
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
        addSubview(monthLabel)
        addSubview(navigationStack)
        navigationStack.addArrangedSubview(previousButton)
        navigationStack.addArrangedSubview(nextButton)
    }

    private func setupConstraints() {
        snp.makeConstraints {
            $0.height.equalTo(Constants.headerHeight)
        }

        monthLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        navigationStack.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        previousButton.snp.makeConstraints {
            $0.size.equalTo(Constants.buttonSize)
        }

        nextButton.snp.makeConstraints {
            $0.size.equalTo(Constants.buttonSize)
        }
    }

    private func setupActions() {
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    // MARK: - Public Methods

    func setMonthText(_ text: String) {
        monthLabel.setText(text, style: .p18, color: .gray050)
    }

    // MARK: - Actions

    @objc private func previousTapped() {
        previousTapSubject.send()
    }

    @objc private func nextTapped() {
        nextTapSubject.send()
    }
}
