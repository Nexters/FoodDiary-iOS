//
//  DetailDateNavigatorView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

/// 상세 화면 날짜 네비게이터 (< 2026년 2월 1일 >)
final class DetailDateNavigatorView: UIView {

    // MARK: - Publishers

    var previousTapPublisher: AnyPublisher<Void, Never> {
        previousTapSubject.eraseToAnyPublisher()
    }

    var nextTapPublisher: AnyPublisher<Void, Never> {
        nextTapSubject.eraseToAnyPublisher()
    }

    private let previousTapSubject = PassthroughSubject<Void, Never>()
    private let nextTapSubject = PassthroughSubject<Void, Never>()

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 28
        static let borderWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 16
    }

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.borderWidth = Constants.borderWidth
        view.layer.borderColor = UIColor.detailPrimaryText.cgColor
        return view
    }()

    private let previousButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        return button
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let shimmerView: ShimmerView = {
        let view = ShimmerView()
        view.backgroundColor = .gray300
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let nextButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
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
        addSubview(containerView)
        containerView.addSubview(previousButton)
        containerView.addSubview(dateLabel)
        containerView.addSubview(shimmerView)
        containerView.addSubview(nextButton)

        previousButton.tintColor = .detailPrimaryText
        dateLabel.textColor = .detailPrimaryText
        nextButton.tintColor = .detailPrimaryText
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalPadding)
            $0.top.bottom.equalToSuperview()
        }

        previousButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.horizontalPadding)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        dateLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        shimmerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(120)
            $0.height.equalTo(20)
        }

        nextButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.horizontalPadding)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }
    }

    private func setupActions() {
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    // MARK: - Public Methods

    func setDateText(_ text: String) {
        dateLabel.setText(text, style: .p15, color: .detailPrimaryText)
    }

    func setNextButtonEnabled(_ enabled: Bool) {
        nextButton.isEnabled = enabled
        nextButton.tintColor = enabled ? .detailPrimaryText : .gray400
    }

    func setPending(_ isPending: Bool) {
        dateLabel.isHidden = isPending
        shimmerView.isHidden = !isPending
        if isPending {
            shimmerView.startAnimating()
        } else {
            shimmerView.stopAnimating()
        }
    }

    // MARK: - Actions

    @objc private func previousTapped() {
        previousTapSubject.send()
    }

    @objc private func nextTapped() {
        nextTapSubject.send()
    }
}
