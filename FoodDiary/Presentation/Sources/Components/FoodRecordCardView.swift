//
//  FoodRecordCardView.swift
//  Presentation
//

import Combine
import DesignSystem
import Kingfisher
import SnapKit
import UIKit

/// 음식 기록 카드 뷰 (WeeklyCalendar와 DailyDetail에서 재사용)
public final class FoodRecordCardView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 20
        static let imageInset: CGFloat = 4
        static let badgeTopInset: CGFloat = 16
        static let badgeLeadingInset: CGFloat = 16
        static let badgeSpacing: CGFloat = 4
        static let badgeHeight: CGFloat = 18
        static let fadeTransitionDuration: Double = 0.25
    }

    // MARK: - State

    private let imageURL: URL?
    private let showsBadges: Bool
    private let timeText: String
    private var isConfigured = false

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

    private let badgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.badgeSpacing
        stack.alignment = .center
        return stack
    }()

    private let timeBadge: PillBadgeView
    private let locationBadge: PillBadgeView?

    // MARK: - Init

    public init(time: String, district: String?, imageURL: URL?) {
        self.imageURL = imageURL
        self.showsBadges = !time.isEmpty || district != nil
        self.timeText = time
        self.timeBadge = PillBadgeView(text: time)
        self.locationBadge = district.map { PillBadgeView(text: $0) }
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !isConfigured else { return }
        isConfigured = true
        configure()
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(foodImageView)
        if showsBadges {
            containerView.addSubview(badgeStackView)
        }

        if !timeText.isEmpty {
            badgeStackView.addArrangedSubview(timeBadge)
        }
        if let locationBadge {
            badgeStackView.addArrangedSubview(locationBadge)
        }
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        foodImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(Constants.imageInset)
        }

        if showsBadges {
            badgeStackView.snp.makeConstraints {
                $0.top.equalTo(foodImageView).offset(Constants.badgeTopInset)
                $0.leading.equalTo(foodImageView).offset(Constants.badgeLeadingInset)
            }
        }
    }

    // MARK: - Configuration

    private func configure() {
        guard let imageURL else {
            showImageUnavailable()
            return
        }
        foodImageView.kf.setImage(
            with: imageURL,
            placeholder: nil,
            options: [
                .transition(.fade(Constants.fadeTransitionDuration)),
                .cacheOriginalImage,
            ]
        )
    }

    private func showImageUnavailable() {
        foodImageView.image = UIImage(systemName: "xmark")
        foodImageView.tintColor = .gray300
        foodImageView.contentMode = .center
    }
}
