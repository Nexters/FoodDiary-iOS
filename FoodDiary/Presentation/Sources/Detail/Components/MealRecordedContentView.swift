//
//  MealRecordedContentView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 음식 기록이 있을 때 표시되는 카드형 콘텐츠
final class MealRecordedContentView: UIView {

    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 20
        static let topRowBottomSpacing: CGFloat = 14
        static let imageSize: CGFloat = 170
        static let imageSpacing: CGFloat = 8
        static let imageCornerRadius: CGFloat = 16
        static let textTopSpacing: CGFloat = 16
        static let hashtagTopSpacing: CGFloat = 6
        static let actionSpacing: CGFloat = 10
        static let badgeSpacing: CGFloat = 12
        static let buttonImagePadding: CGFloat = 4
    }

    private struct CardItem {
        let record: FoodRecord
        let imageURL: URL
    }

    private let onCopyTapped: ((FoodRecord) -> Void)?
    private let onShareTapped: ((FoodRecord) -> Void)?

    private var cardItems: [CardItem] = []
    private var currentRecord: FoodRecord?

    private let badgeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.badgeSpacing
        return stackView
    }()

    private let actionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.actionSpacing
        return stackView
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            DetailFoodCardCell.self,
            forCellWithReuseIdentifier: DetailFoodCardCell.reuseIdentifier
        )
        return collectionView
    }()

    private let textContainerView = UIView()
    private let restaurantNameLabel = UILabel()
    private let hashtagLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var copyButton = ActionButton(
        title: "복사",
        image: DesignSystemAsset.iconCopy.image
    )

    private lazy var shareButton = ActionButton(
        title: "공유",
        image: DesignSystemAsset.iconShare.image
    )

    init(
        records: [FoodRecord],
        onCopyTapped: ((FoodRecord) -> Void)? = nil,
        onShareTapped: ((FoodRecord) -> Void)? = nil
    ) {
        self.onCopyTapped = onCopyTapped
        self.onShareTapped = onShareTapped
        super.init(frame: .zero)

        cardItems = records.flatMap { record in
            record.imageURLs.map { CardItem(record: record, imageURL: $0) }
        }

        setupUI()
        setupConstraints()
        setupActions()
        configureContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .detailCardBackground
        layer.cornerRadius = 10
        clipsToBounds = true

        addSubview(badgeStackView)
        addSubview(actionStackView)
        addSubview(collectionView)
        addSubview(textContainerView)

        textContainerView.addSubview(restaurantNameLabel)
        textContainerView.addSubview(hashtagLabel)

        actionStackView.addArrangedSubview(copyButton)
        actionStackView.addArrangedSubview(shareButton)
    }

    private func setupConstraints() {
        badgeStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.verticalInset)
            $0.leading.equalToSuperview().inset(Constants.horizontalInset)
            $0.centerY.equalTo(actionStackView)
            $0.trailing.lessThanOrEqualTo(actionStackView.snp.leading).offset(-12)
        }

        actionStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.verticalInset)
            $0.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(actionStackView.snp.bottom).offset(Constants.topRowBottomSpacing)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Constants.imageSize)
        }

        textContainerView.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(Constants.textTopSpacing)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(Constants.verticalInset)
        }

        restaurantNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        hashtagLabel.snp.makeConstraints {
            $0.top.equalTo(restaurantNameLabel.snp.bottom).offset(Constants.hashtagTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.bottom.equalToSuperview()
        }
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(Constants.imageSize),
            heightDimension: .absolute(Constants.imageSize)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])

        // 페이지네이션 없이 자유 스크롤 (다음 이미지가 일부 보임)
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Constants.imageSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: Constants.horizontalInset,
            bottom: 0,
            trailing: Constants.horizontalInset
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupActions() {
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }

    private func configureContent() {
        if let record = cardItems.first?.record {
            currentRecord = record
            configureBadges(with: record)
            configureText(with: record)
        }
    }

    private func configureBadges(with record: FoodRecord) {
        badgeStackView.arrangedSubviews.forEach {
            badgeStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let timeBadge = PillBadgeView(text: record.formattedShortTime)
        badgeStackView.addArrangedSubview(timeBadge)

        if let district = record.district, !district.isEmpty {
            let districtBadge = PillBadgeView(text: district)
            badgeStackView.addArrangedSubview(districtBadge)
        }
    }

    private func configureText(with record: FoodRecord) {
        if let restaurantName = record.restaurantName, !restaurantName.isEmpty {
            restaurantNameLabel.attributedText = NSAttributedString(
                string: restaurantName,
                attributes: [
                    .font: DesignSystemFontFamily.Pretendard.semiBold.font(size: 14),
                    .foregroundColor: UIColor.detailPrimaryText,
                    .kern: -0.21
                ]
            )
        } else {
            restaurantNameLabel.setText("수정버튼을 눌러 내용을 기록해 보세요", style: .p12, color: .detailMutedText)
        }

        let hashtagText = record.hashtags.map { "#\($0)" }.joined(separator: " ")
        hashtagLabel.attributedText = NSAttributedString(
            string: hashtagText,
            attributes: [
                .font: DesignSystemFontFamily.Pretendard.regular.font(size: 10),
                .foregroundColor: UIColor.detailMutedText,
                .kern: -0.15
            ]
        )
        hashtagLabel.isHidden = hashtagText.isEmpty
    }

    @objc private func copyTapped() {
        guard let currentRecord else { return }
        onCopyTapped?(currentRecord)
    }

    @objc private func shareTapped() {
        guard let currentRecord else { return }
        onShareTapped?(currentRecord)
    }
}

extension MealRecordedContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cardItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DetailFoodCardCell.reuseIdentifier,
                for: indexPath
            ) as? DetailFoodCardCell
        else {
            return UICollectionViewCell()
        }

        let cardItem = cardItems[indexPath.item]
        cell.configure(
            time: "",
            district: nil,
            imageURL: cardItem.imageURL,
            cornerRadius: Constants.imageCornerRadius
        )
        return cell
    }
}

extension MealRecordedContentView: UICollectionViewDelegate {}

private final class ActionButton: UIButton {
    init(title: String, image: UIImage?) {
        super.init(frame: .zero)

        var configuration = UIButton.Configuration.plain()
        configuration.image = image
        configuration.imagePadding = 4
        configuration.contentInsets = .zero
        self.configuration = configuration
        tintColor = .detailPrimaryText
        imageView?.contentMode = .scaleAspectFit
        imageView?.snp.makeConstraints {
            $0.width.height.equalTo(18)
        }
        setAttributedTitle(
            NSAttributedString(
                string: title,
                attributes: [
                    .font: DesignSystemFontFamily.Pretendard.regular.font(size: 12),
                    .foregroundColor: UIColor.detailPrimaryText,
                    .kern: -0.18
                ]
            ),
            for: .normal
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
