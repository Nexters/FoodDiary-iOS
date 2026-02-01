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
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let foodImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        iv.backgroundColor = DesignSystemAsset.gray300.color
        return iv
    }()

    private let mealTypeBadge = MealTypeBadgeView()

    private let infoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
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
        iv.image = UIImage(systemName: "doc.on.doc")
        iv.tintColor = DesignSystemAsset.gray500.color
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
        containerView.addSubview(mealTypeBadge)

        // 정보 영역
        containerView.addSubview(infoContainerView)
        infoContainerView.addSubview(restaurantNameLabel)
        infoContainerView.addSubview(addressLabel)
        infoContainerView.addSubview(copyButtonContainer)
        copyButtonContainer.addSubview(copyIconImageView)
        copyButtonContainer.addSubview(copyLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 이미지 영역 - 상단
        foodImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(5)
            $0.height.equalTo(foodImageView.snp.width).multipliedBy(0.75)
        }

        mealTypeBadge.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(19)
            $0.top.equalToSuperview().offset(19)
        }

        // 정보 영역 - 하단
        infoContainerView.snp.makeConstraints {
            $0.top.equalTo(foodImageView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        restaurantNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(copyButtonContainer.snp.leading).offset(-12)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(restaurantNameLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(copyButtonContainer.snp.leading).offset(-12)
            $0.bottom.equalToSuperview().offset(-16)
        }

        copyButtonContainer.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(40)
        }

        copyIconImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(24)
        }

        copyLabel.snp.makeConstraints {
            $0.top.equalTo(copyIconImageView.snp.bottom).offset(2)
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
        mealTypeBadge.configure(with: record.mealType)

        if let name = record.restaurantName {
            restaurantNameLabel.setText(name, style: .hd16, color: DesignSystemAsset.gray900.color)
            restaurantNameLabel.isHidden = false
        } else {
            restaurantNameLabel.isHidden = true
        }

        if let address = record.address {
            addressLabel.setText(address, style: .p12, color: DesignSystemAsset.gray500.color)
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
                .transition(.fade(0.25)),
                .cacheOriginalImage
            ]
        )
    }

    // MARK: - Actions

    @objc private func copyButtonTapped() {
        guard let address = record.address else { return }
        copyTapSubject.send(address)
    }
}
