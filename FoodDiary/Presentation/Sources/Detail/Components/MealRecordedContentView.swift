//
//  MealRecordedContentView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 음식 기록이 있을 때 표시되는 카드 캐러셀 + 정보 영역
final class MealRecordedContentView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cardSpacing: CGFloat = 12
        static let pageControlTopSpacing: CGFloat = 8
        static let pageControlHeight: CGFloat = 20
        static let infoTopSpacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 10
        static let hashtagTopSpacing: CGFloat = 16
        static let buttonImagePadding: CGFloat = 4
        static let textHorizontalInset: CGFloat = 10
        static let noteTopSpacing: CGFloat = 16
    }

    // MARK: - Types

    private struct CardItem {
        let record: FoodRecord
        let imageURL: URL
    }

    // MARK: - Handlers

    private let onCopyTapped: ((FoodRecord) -> Void)?
    private let onShareTapped: ((FoodRecord) -> Void)?

    // MARK: - State

    private var cardItems: [CardItem] = []
    private var currentRecord: FoodRecord?

    // MARK: - Constraints

    private var labelTrailingWithButton: Constraint?
    private var labelTrailingWithoutButton: Constraint?
    private var infoTopWithPageControl: Constraint?
    private var infoTopWithoutPageControl: Constraint?
    private var infoBottomConstraint: Constraint?

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.isScrollEnabled = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(
            DetailFoodCardCell.self, forCellWithReuseIdentifier: DetailFoodCardCell.reuseIdentifier)
        return cv
    }()

    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .primary
        pc.pageIndicatorTintColor = .detailStroke
        pc.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        return pc
    }()

    private let infoContainerView = UIView()

    private let restaurantNameLabel = UILabel()

    private let copyButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = DesignSystemAsset.iconCopy.image
            .withRenderingMode(.alwaysTemplate)
        config.imagePadding = Constants.buttonImagePadding
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        return button
    }()

    private let shareButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "link")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        config.imagePadding = Constants.buttonImagePadding
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        return button
    }()

    private let hashtagLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private var noteView: NoteContentView?

    // MARK: - Init

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

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .detailCardBackground
        layer.cornerRadius = 10
        clipsToBounds = true

        addSubview(collectionView)
        addSubview(pageControl)
        addSubview(infoContainerView)

        infoContainerView.addSubview(restaurantNameLabel)
        infoContainerView.addSubview(copyButton)
        infoContainerView.addSubview(shareButton)
        infoContainerView.addSubview(hashtagLabel)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(collectionView.snp.width)
        }

        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(Constants.pageControlTopSpacing)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.pageControlHeight)
        }

        infoContainerView.snp.makeConstraints {
            infoTopWithPageControl = $0.top
                .equalTo(pageControl.snp.bottom).offset(Constants.infoTopSpacing).constraint
            infoTopWithoutPageControl = $0.top
                .equalTo(collectionView.snp.bottom).offset(Constants.infoTopSpacing).constraint
            $0.leading.trailing.equalToSuperview().inset(Constants.textHorizontalInset)
            $0.bottom.equalToSuperview()
        }
        infoTopWithoutPageControl?.deactivate()

        restaurantNameLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            labelTrailingWithButton = $0.trailing
                .lessThanOrEqualTo(copyButton.snp.leading).offset(-8).constraint
            labelTrailingWithoutButton = $0.trailing
                .lessThanOrEqualToSuperview().constraint
        }
        labelTrailingWithoutButton?.deactivate()

        shareButton.snp.makeConstraints {
            $0.centerY.equalTo(restaurantNameLabel)
            $0.trailing.equalToSuperview()
            $0.height.greaterThanOrEqualTo(44)
        }

        copyButton.snp.makeConstraints {
            $0.centerY.equalTo(restaurantNameLabel)
            $0.trailing.equalTo(shareButton.snp.leading)
            $0.height.greaterThanOrEqualTo(44)
        }

        hashtagLabel.snp.makeConstraints {
            $0.top.equalTo(restaurantNameLabel.snp.bottom).offset(Constants.hashtagTopSpacing)
            $0.leading.trailing.equalToSuperview()
        }
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: Constants.cardSpacing / 2,
            bottom: 0,
            trailing: Constants.cardSpacing / 2
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.visibleItemsInvalidationHandler = { [weak self] _, offset, environment in
            let pageWidth = environment.container.contentSize.width
            let currentPage = Int((offset.x + pageWidth / 2) / pageWidth)
            self?.pageControl.currentPage = currentPage
            self?.updateCurrentRecord(for: currentPage)
        }

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupActions() {
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }

    private func configureContent() {
        pageControl.numberOfPages = cardItems.count
        pageControl.currentPage = 0

        let showPageControl = cardItems.count > 1
        pageControl.isHidden = !showPageControl
        if showPageControl {
            infoTopWithPageControl?.activate()
            infoTopWithoutPageControl?.deactivate()
        } else {
            infoTopWithPageControl?.deactivate()
            infoTopWithoutPageControl?.activate()
        }

        if let record = cardItems.first?.record {
            currentRecord = record
            configureInfoSection(with: record)
        }
    }

    private func configureInfoSection(with record: FoodRecord) {
        let hasName = !(record.restaurantName ?? "").isEmpty

        if hasName {
            restaurantNameLabel.setText(record.restaurantName!, style: .hd16, color: .detailPrimaryText)
            copyButton.isHidden = false
            shareButton.isHidden = false
            labelTrailingWithButton?.activate()
            labelTrailingWithoutButton?.deactivate()
        } else {
            restaurantNameLabel.setText("수정버튼을 눌러 내용을 기록해 보세요", style: .p12, color: .detailMutedText)
            copyButton.isHidden = true
            shareButton.isHidden = true
            labelTrailingWithButton?.deactivate()
            labelTrailingWithoutButton?.activate()
        }

        copyButton.tintColor = .detailPrimaryText
        shareButton.tintColor = .detailPrimaryText

        let copyTitle = Typography.p12.styled("복사", color: .detailPrimaryText)
        copyButton.setAttributedTitle(copyTitle, for: .normal)

        let shareTitle = Typography.p12.styled("공유", color: .detailPrimaryText)
        shareButton.setAttributedTitle(shareTitle, for: .normal)

        let hashtagText = record.hashtags.map { "#\($0)" }.joined(separator: " ")
        hashtagLabel.setText(hashtagText, style: .p12, color: .detailMutedText)
        hashtagLabel.isHidden = record.hashtags.isEmpty

        configureNoteSection(with: record)
    }

    private func configureNoteSection(with record: FoodRecord) {
        noteView?.removeFromSuperview()
        noteView = nil
        infoBottomConstraint?.deactivate()

        let hasNote = !(record.note ?? "").isEmpty

        if hasNote {
            let newNoteView = NoteContentView(note: record.note!)
            infoContainerView.addSubview(newNoteView)
            newNoteView.snp.makeConstraints {
                $0.top.equalTo(hashtagLabel.snp.bottom).offset(Constants.noteTopSpacing)
                $0.leading.trailing.equalToSuperview()
                infoBottomConstraint = $0.bottom.equalToSuperview().constraint
            }
            noteView = newNoteView
        } else {
            hashtagLabel.snp.makeConstraints {
                infoBottomConstraint = $0.bottom.equalToSuperview().constraint
            }
        }
    }

    private func updateCurrentRecord(for page: Int) {
        guard page >= 0, page < cardItems.count else { return }
        let record = cardItems[page].record
        guard record != currentRecord else { return }
        currentRecord = record
        configureInfoSection(with: record)
    }

    // MARK: - Actions

    @objc private func pageControlChanged() {
        let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    @objc private func copyTapped() {
        guard let record = currentRecord else { return }
        onCopyTapped?(record)
    }

    @objc private func shareTapped() {
        guard let record = currentRecord else { return }
        onShareTapped?(record)
    }
}

// MARK: - UICollectionViewDataSource

extension MealRecordedContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
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
            time: cardItem.record.formattedShortTime,
            district: cardItem.record.district,
            imageURL: cardItem.imageURL
        )

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MealRecordedContentView: UICollectionViewDelegate {}
