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
        static let imageInset: CGFloat = 5
        static let imageAspectRatio: CGFloat = 0.90
        static let badgeLeadingOffset: CGFloat = 18
        static let infoHorizontalPadding: CGFloat = 18
        static let infoVerticalPadding: CGFloat = 16
        static let labelSpacing: CGFloat = 4
        static let infoStackSpacing: CGFloat = 12
        static let copyButtonWidth: CGFloat = 24
        static let copyIconSize: CGFloat = 18
        static let copyLabelTopSpacing: CGFloat = 2
        static let fadeTransitionDuration: Double = 0.25
    }

    // MARK: - Publishers

    private let copyTapSubject = PassthroughSubject<String, Never>()
    public var copyTapPublisher: AnyPublisher<String, Never> {
        copyTapSubject.eraseToAnyPublisher()
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
        iv.layer.cornerRadius = Constants.cornerRadius
        iv.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        iv.backgroundColor = .gray300
        return iv
    }()

    private let genreBadge: BadgeView

    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constants.infoStackSpacing
        stack.backgroundColor = .white
        return stack
    }()

    private let labelStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.labelSpacing
        return stack
    }()

    private let restaurantNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private let copyButtonContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let copyIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.iconCopy.image
        iv.tintColor = .gray500
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let copyLabel: UILabel = {
        let label = UILabel()
        label.setText("복사", style: .p10, color: .grayBase)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    public init(record: FoodRecord) {
        self.record = record
        self.genreBadge = BadgeView(genre: record.genre)
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
        containerView.addSubview(genreBadge)

        // 정보 영역
        containerView.addSubview(infoStackView)

        labelStackView.addArrangedSubview(restaurantNameLabel)
        labelStackView.addArrangedSubview(addressLabel)

        infoStackView.addArrangedSubview(labelStackView)
        infoStackView.addArrangedSubview(copyButtonContainer)

        copyButtonContainer.addSubview(copyIconImageView)
        copyButtonContainer.addSubview(copyLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 이미지 영역 - 상단
        foodImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(Constants.imageInset)
            $0.height.equalTo(foodImageView.snp.width).multipliedBy(Constants.imageAspectRatio).priority(.high)
        }

        genreBadge.snp.makeConstraints {
            $0.leading.equalTo(foodImageView).offset(Constants.badgeLeadingOffset)
            $0.centerY.equalTo(foodImageView.snp.bottom)
        }

        // 정보 영역 - 하단
        infoStackView.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(foodImageView.snp.bottom).offset(Constants.infoVerticalPadding)
            $0.leading.trailing.equalToSuperview().inset(Constants.infoHorizontalPadding)
            $0.bottom.equalToSuperview().inset(Constants.infoVerticalPadding)
        }

        copyButtonContainer.snp.makeConstraints {
            $0.width.equalTo(Constants.copyButtonWidth)
        }

        copyIconImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(Constants.copyIconSize)
        }

        copyLabel.snp.makeConstraints {
            $0.top.equalTo(copyIconImageView.snp.bottom).offset(Constants.copyLabelTopSpacing)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    private func setupActions() {
        let copyTapGesture = UITapGestureRecognizer(
            target: self, action: #selector(copyButtonTapped))
        copyButtonContainer.addGestureRecognizer(copyTapGesture)
        copyButtonContainer.isUserInteractionEnabled = true
    }

    // MARK: - Configuration

    private func configure() {
        if let name = record.restaurantName {
            restaurantNameLabel.setText(name, style: .hd16, color: .gray900)
            restaurantNameLabel.isHidden = false
        } else {
            restaurantNameLabel.isHidden = true
        }

        if let address = record.address {
            addressLabel.setText(address, style: .p10, color: .gray500)
            addressLabel.isHidden = false
            copyButtonContainer.isHidden = false
        } else {
            addressLabel.isHidden = true
            copyButtonContainer.isHidden = true
        }

        // 첫 번째 이미지 URL로 이미지 로드
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

    // MARK: - Actions

    @objc private func copyButtonTapped() {
        guard let address = record.address else { return }
        copyTapSubject.send(address)
    }
}
