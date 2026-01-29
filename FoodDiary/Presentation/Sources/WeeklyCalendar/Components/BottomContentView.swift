//
//  BottomContentView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

/// 하단 영역 (+버튼 또는 기록된 이미지 스택)
final class BottomContentView: UIView {

    // MARK: - Publisher

    var addButtonTapPublisher: AnyPublisher<Void, Never> {
        addButtonTapSubject.eraseToAnyPublisher()
    }

    private let addButtonTapSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return view
    }()

    private let addButtonOuterRing: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.white.cgColor
        return view
    }()

    private let addButtonContainer: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystemAsset.primary.color
        view.layer.cornerRadius = 18
        return view
    }()

    private let addButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        return button
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 음식 사진을 추가해보세요."
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()

    private let recordedImagesStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = -20
        sv.isHidden = true
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
        addSubview(containerView)
        containerView.addSubview(addButtonOuterRing)
        addButtonOuterRing.addSubview(addButtonContainer)
        addButtonContainer.addSubview(addButton)
        containerView.addSubview(placeholderLabel)
        containerView.addSubview(recordedImagesStackView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }

        addButtonOuterRing.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(48)
        }

        addButtonContainer.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(36)
        }

        addButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        placeholderLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(addButtonOuterRing.snp.bottom).offset(16)
        }

        recordedImagesStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(80)
        }
    }

    private func setupActions() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    // MARK: - Configuration

    func configure(hasRecords: Bool, records: [FoodRecord]) {
        // 기록 여부와 관계없이 항상 + 버튼 표시
        // 이미지 스택 기능은 추후 디자인 확정 후 구현
        addButtonOuterRing.isHidden = false
        placeholderLabel.isHidden = false
        recordedImagesStackView.isHidden = true

        if hasRecords {
            placeholderLabel.text = "사진을 더 추가해보세요."
        } else {
            placeholderLabel.text = "오늘의 음식 사진을 추가해보세요."
        }
    }

    private func updateRecordedImagesStack(with records: [FoodRecord]) {
        recordedImagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let maxDisplayCount = min(records.count, 3)
        (0..<maxDisplayCount).forEach { index in
            let imageView = UIImageView()
            imageView.backgroundColor = DesignSystemAsset.disabled.color
            imageView.layer.cornerRadius = 8
            imageView.layer.borderWidth = 2
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.clipsToBounds = true
            imageView.snp.makeConstraints { $0.size.equalTo(CGSize(width: 60, height: 80)) }

            // 스택 효과를 위해 zPosition 조절
            imageView.layer.zPosition = CGFloat(maxDisplayCount - index)
            recordedImagesStackView.addArrangedSubview(imageView)
        }
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        addButtonTapSubject.send()
    }
}
