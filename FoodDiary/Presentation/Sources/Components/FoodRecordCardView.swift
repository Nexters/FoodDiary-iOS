//
//  FoodRecordCardView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
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

    public let record: FoodRecord

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

    public init(record: FoodRecord) {
        self.record = record
        self.timeBadge = PillBadgeView(text: record.formattedShortTime)
        self.locationBadge = record.district.map { PillBadgeView(text: $0) }
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
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
        containerView.addSubview(badgeStackView)

        badgeStackView.addArrangedSubview(timeBadge)
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

        badgeStackView.snp.makeConstraints {
            $0.top.equalTo(foodImageView).offset(Constants.badgeTopInset)
            $0.leading.equalTo(foodImageView).offset(Constants.badgeLeadingInset)
        }
    }

    // MARK: - Configuration

    private func configure() {
        setImageURL(record.imageURLs.first)
    }

    public func setImage(_ image: UIImage?) {
        foodImageView.image = image
    }

    public func setImageURL(_ url: URL?) {
        foodImageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [
                .transition(.fade(Constants.fadeTransitionDuration)),
                .cacheOriginalImage,
            ]
        )
    }
}
