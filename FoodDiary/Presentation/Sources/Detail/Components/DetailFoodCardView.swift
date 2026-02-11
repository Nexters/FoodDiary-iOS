//
//  DetailFoodCardView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import Kingfisher
import SnapKit
import UIKit

/// 상세 화면용 음식 기록 카드 뷰
final class DetailFoodCardView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 20
        static let imageInset: CGFloat = 5
        static let badgeTopInset: CGFloat = 18
        static let badgeLeadingInset: CGFloat = 16
        static let badgeSpacing: CGFloat = 4
        static let bottomContentTopInset: CGFloat = 12
        static let bottomContentHorizontalInset: CGFloat = 8
        static let bottomContentBottomInset: CGFloat = 12
        static let buttonSpacing: CGFloat = 16
        static let fadeTransitionDuration: Double = 0.25
    }

    // MARK: - Publishers

    var copyTapPublisher: AnyPublisher<FoodRecord, Never> {
        copyTapSubject.eraseToAnyPublisher()
    }

    var shareTapPublisher: AnyPublisher<FoodRecord, Never> {
        shareTapSubject.eraseToAnyPublisher()
    }

    private let copyTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let shareTapSubject = PassthroughSubject<FoodRecord, Never>()

    // MARK: - State

    let record: FoodRecord
    private let imageURL: URL

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Constants.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let foodImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = Constants.cornerRadius - Constants.imageInset
        iv.backgroundColor = .gray300
        return iv
    }()

    private let topBadgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.badgeSpacing
        stack.alignment = .center
        return stack
    }()

    private let timeBadge: PillBadgeView
    private let locationBadge: PillBadgeView?

    // 이미지 아래 콘텐츠 영역
    private let bottomContentView = UIView()

    private let restaurantLabel: UILabel = {
        let label = UILabel()
        label.textColor = .sdBase
        return label
    }()

    private let hashtagsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray500
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var copyStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [copyButton, copyLabel])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private lazy var shareStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [shareButton, shareLabel])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private lazy var actionButtonsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [copyStackView, shareStackView])
        stack.axis = .horizontal
        stack.spacing = Constants.buttonSpacing
        stack.alignment = .center
        return stack
    }()

    private let copyButton: UIButton = {
        let button = UIButton()
        button.setImage(DesignSystemAsset.iconCopy.image, for: .normal)
        button.tintColor = .gray500
        return button
    }()

    private let copyLabel: UILabel = {
        let label = UILabel()
        label.text = "복사"
        label.textColor = .gray500
        return label
    }()

    private let shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.tintColor = .gray500
        return button
    }()

    private let shareLabel: UILabel = {
        let label = UILabel()
        label.text = "공유"
        label.textColor = .gray500
        return label
    }()

    // MARK: - Init

    init(record: FoodRecord, imageURL: URL) {
        self.record = record
        self.imageURL = imageURL
        self.timeBadge = PillBadgeView(text: record.formattedShortTime)
        self.locationBadge = record.district.map { PillBadgeView(text: $0) }
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)

        // 이미지 영역
        containerView.addSubview(foodImageView)
        containerView.addSubview(topBadgeStackView)

        topBadgeStackView.addArrangedSubview(timeBadge)
        if let locationBadge {
            topBadgeStackView.addArrangedSubview(locationBadge)
        }

        // 하단 콘텐츠 영역
        containerView.addSubview(bottomContentView)
        bottomContentView.addSubview(restaurantLabel)
        bottomContentView.addSubview(hashtagsLabel)
        bottomContentView.addSubview(actionButtonsStackView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        foodImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(Constants.imageInset)
        }

        topBadgeStackView.snp.makeConstraints {
            $0.top.equalTo(foodImageView).offset(Constants.badgeTopInset)
            $0.leading.equalTo(foodImageView).offset(Constants.badgeLeadingInset)
        }

        bottomContentView.snp.makeConstraints {
            $0.top.equalTo(foodImageView.snp.bottom).offset(Constants.bottomContentTopInset)
            $0.leading.trailing.equalToSuperview().inset(Constants.bottomContentHorizontalInset)
            $0.bottom.equalToSuperview().offset(-Constants.bottomContentBottomInset)
        }

        restaurantLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }

        hashtagsLabel.snp.makeConstraints {
            $0.top.equalTo(restaurantLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(actionButtonsStackView.snp.leading).offset(-12)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        actionButtonsStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        copyButton.snp.makeConstraints {
            $0.size.equalTo(20)
        }

        shareButton.snp.makeConstraints {
            $0.size.equalTo(20)
        }
    }

    private func setupActions() {
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }

    // MARK: - Configuration

    private func configure() {
        // Image
        foodImageView.kf.setImage(
            with: imageURL,
            options: [
                .transition(.fade(Constants.fadeTransitionDuration)),
                .cacheOriginalImage,
            ]
        )

        // Restaurant name
        if let restaurantName = record.restaurantName {
            restaurantLabel.setText(restaurantName, style: .hd16)
            restaurantLabel.isHidden = false
        } else {
            restaurantLabel.isHidden = true
        }

        // Hashtags
        if !record.hashtags.isEmpty {
            let hashtagText = record.hashtags.map { "#\($0)" }.joined(separator: " ")
            hashtagsLabel.setText(hashtagText, style: .p12)
            hashtagsLabel.isHidden = false
        } else {
            hashtagsLabel.isHidden = true
        }

        // Button labels
        copyLabel.setText("복사", style: .p10)
        shareLabel.setText("공유", style: .p10)
    }

    // MARK: - Actions

    @objc private func copyTapped() {
        copyTapSubject.send(record)
    }

    @objc private func shareTapped() {
        shareTapSubject.send(record)
    }
}
