//
//  EmptyFoodRecordView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

/// 음식 기록이 없을 때 표시되는 빈 상태 뷰
final class EmptyFoodRecordView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let addButtonSize: CGFloat = 120
        static let addButtonCenterYOffset: CGFloat = -20
        static let placeholderTopSpacing: CGFloat = 16
        static let photoCountTopSpacing: CGFloat = 4
    }

    // MARK: - Publishers

    var addButtonTapPublisher: AnyPublisher<Void, Never> {
        addButtonTapSubject.eraseToAnyPublisher()
    }

    private let addButtonTapSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Components

    private let addButton: UIButton = {
        let button = UIButton()
        button.setImage(DesignSystemAsset.add.image, for: .normal)
        return button
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let photoCountLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    init(photoCount: Int) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        configure(photoCount: photoCount)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(addButton)
        addSubview(placeholderLabel)
        addSubview(photoCountLabel)
    }

    private func setupConstraints() {
        addButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(Constants.addButtonCenterYOffset)
            $0.width.height.equalTo(Constants.addButtonSize)
        }

        placeholderLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(addButton.snp.bottom).offset(Constants.placeholderTopSpacing)
        }

        photoCountLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(placeholderLabel.snp.bottom).offset(Constants.photoCountTopSpacing)
        }
    }

    private func setupActions() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    // MARK: - Configuration

    func configure(photoCount: Int) {
        if photoCount > 0 {
            placeholderLabel.setText("음식 사진을 추가해보세요.", style: .p14, color: .gray050)
            photoCountLabel.setText("올리지 않은 음식 사진 \(photoCount)장", style: .p12, color: .gray050)
            photoCountLabel.isHidden = false
        } else {
            placeholderLabel.setText("오늘의 음식 사진을 추가해보세요.", style: .p14, color: .gray050)
            photoCountLabel.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        addButtonTapSubject.send()
    }
}
