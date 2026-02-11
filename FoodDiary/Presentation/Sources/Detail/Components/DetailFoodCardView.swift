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
        static let bottomContentInset: CGFloat = 18
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

    private let bottomOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()

    private let genreBadge: PillBadgeView

    private let restaurantLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()

    private let hashtagsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let copyButton: UIButton = {
        let button = UIButton()
        button.setImage(DesignSystemAsset.iconCopy.image, for: .normal)
        button.tintColor = .white
        return button
    }()

    private let copyLabel: UILabel = {
        let label = UILabel()
        label.text = "복사"
        label.textColor = .white
        return label
    }()

    private let shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let shareLabel: UILabel = {
        let label = UILabel()
        label.text = "공유"
        label.textColor = .white
        return label
    }()

    // MARK: - Init

    init(record: FoodRecord, imageURL: URL) {
        self.record = record
        self.imageURL = imageURL
        self.timeBadge = PillBadgeView(text: record.formattedShortTime)
        self.locationBadge = record.district.map { PillBadgeView(text: $0) }
        self.genreBadge = PillBadgeView(text: record.genre.rawValue)
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
        containerView.addSubview(foodImageView)
        containerView.addSubview(topBadgeStackView)
        containerView.addSubview(bottomOverlayView)
        containerView.addSubview(genreBadge)

        topBadgeStackView.addArrangedSubview(timeBadge)
        if let locationBadge {
            topBadgeStackView.addArrangedSubview(locationBadge)
        }

        // Bottom overlay contents
        bottomOverlayView.addSubview(restaurantLabel)
        bottomOverlayView.addSubview(hashtagsLabel)
        bottomOverlayView.addSubview(copyButton)
        bottomOverlayView.addSubview(copyLabel)
        bottomOverlayView.addSubview(shareButton)
        bottomOverlayView.addSubview(shareLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        foodImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Constants.imageInset)
        }

        topBadgeStackView.snp.makeConstraints {
            $0.top.equalTo(foodImageView).offset(Constants.badgeTopInset)
            $0.leading.equalTo(foodImageView).offset(Constants.badgeLeadingInset)
        }

        bottomOverlayView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(foodImageView)
        }

        genreBadge.snp.makeConstraints {
            $0.leading.equalTo(bottomOverlayView).offset(Constants.bottomContentInset)
            $0.centerY.equalTo(bottomOverlayView.snp.top)
        }

        restaurantLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.bottomContentInset)
            $0.top.equalToSuperview().offset(Constants.bottomContentInset)
        }

        hashtagsLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.bottomContentInset)
            $0.top.equalTo(restaurantLabel.snp.bottom).offset(2)
            $0.trailing.lessThanOrEqualTo(copyButton.snp.leading).offset(-12)
            $0.bottom.equalToSuperview().offset(-Constants.bottomContentInset)
        }

        shareButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.bottomContentInset)
            $0.top.equalToSuperview().offset(Constants.bottomContentInset)
            $0.size.equalTo(24)
        }

        shareLabel.snp.makeConstraints {
            $0.centerX.equalTo(shareButton)
            $0.top.equalTo(shareButton.snp.bottom).offset(4)
        }

        copyButton.snp.makeConstraints {
            $0.trailing.equalTo(shareButton.snp.leading).offset(-24)
            $0.top.equalToSuperview().offset(Constants.bottomContentInset)
            $0.size.equalTo(24)
        }

        copyLabel.snp.makeConstraints {
            $0.centerX.equalTo(copyButton)
            $0.top.equalTo(copyButton.snp.bottom).offset(4)
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
