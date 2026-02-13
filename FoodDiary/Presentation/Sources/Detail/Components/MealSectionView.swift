//
//  MealSectionView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

/// 식사 타입별 섹션 뷰 (아침, 점심, 저녁)
final class MealSectionView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let titleTopInset: CGFloat = 24
        static let contentTopInset: CGFloat = 16
        static let horizontalInset: CGFloat = 24
        static let cardSpacing: CGFloat = 12
        static let pageControlHeight: CGFloat = 20
        static let emptyStateImageSize: CGFloat = 120
        static let emptyCardCornerRadius: CGFloat = 20
        static let emptyCardBorderWidth: CGFloat = 1
        static let emptyCardVerticalPadding: CGFloat = 40
    }

    // MARK: - Types

    private struct CardItem {
        let record: FoodRecord
        let imageURL: URL
    }

    // MARK: - Publishers

    var copyTapPublisher: AnyPublisher<FoodRecord, Never> {
        copyTapSubject.eraseToAnyPublisher()
    }

    var shareTapPublisher: AnyPublisher<FoodRecord, Never> {
        shareTapSubject.eraseToAnyPublisher()
    }

    var editTapPublisher: AnyPublisher<MealType, Never> {
        editTapSubject.eraseToAnyPublisher()
    }

    private let copyTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let shareTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let editTapSubject = PassthroughSubject<MealType, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State

    private let mealType: MealType
    private var cardItems: [CardItem] = []

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()

    private let editButton: UIButton = {
        let button = UIButton()
        button.setTitle("수정", for: .normal)
        button.setTitleColor(.gray400, for: .normal)
        button.isHidden = true
        return button
    }()

    private let contentContainerView: UIView = {
        let view = UIView()
        return view
    }()

    // CollectionView for cards
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(DetailFoodCardCell.self, forCellWithReuseIdentifier: DetailFoodCardCell.reuseIdentifier)
        return cv
    }()

    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .primary
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
        pc.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        return pc
    }()

    // Empty State View
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyCardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.emptyCardCornerRadius
        view.layer.borderWidth = Constants.emptyCardBorderWidth
        view.layer.borderColor = UIColor.gray600.cgColor
        return view
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.add.image
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 음식 사진을 추가해보세요."
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    init(mealType: MealType) {
        self.mealType = mealType
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        configureTitleLabel()
        configureEditButton()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(editButton)
        addSubview(contentContainerView)

        // CollectionView
        contentContainerView.addSubview(collectionView)
        contentContainerView.addSubview(pageControl)

        // Empty state
        contentContainerView.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyCardView)
        emptyCardView.addSubview(emptyImageView)
        emptyCardView.addSubview(emptyLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.titleTopInset)
            $0.leading.equalToSuperview().offset(Constants.horizontalInset)
        }

        editButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-Constants.horizontalInset)
        }

        contentContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Constants.contentTopInset)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.height.equalTo(collectionView.snp.width)
        }

        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.pageControlHeight)
            $0.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        emptyCardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(Constants.emptyCardVerticalPadding)
            $0.size.equalTo(Constants.emptyStateImageSize)
        }

        emptyLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(emptyImageView.snp.bottom).offset(16)
            $0.bottom.equalToSuperview().offset(-Constants.emptyCardVerticalPadding)
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
        }

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupActions() {
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
    }

    private func configureTitleLabel() {
        let title: String
        switch mealType {
        case .breakfast:
            title = "아침"
        case .lunch:
            title = "점심"
        case .dinner:
            title = "저녁"
        case .lateNight:
            title = "야식"
        }
        titleLabel.setText(title, style: .hd20)
    }

    private func configureEditButton() {
        editButton.titleLabel?.setText("수정", style: .p14)
    }

    // MARK: - Public Methods

    func configure(records: [FoodRecord]) {
        // Flatten records to card items (one card per image)
        cardItems = records.flatMap { record in
            record.imageURLs.map { CardItem(record: record, imageURL: $0) }
        }

        if cardItems.isEmpty {
            showEmptyState()
        } else {
            showCardState()
        }
    }

    // MARK: - Private Methods

    private func showEmptyState() {
        collectionView.isHidden = true
        pageControl.isHidden = true
        emptyStateView.isHidden = false
        editButton.isHidden = true

        let emptyText: String
        switch mealType {
        case .lunch:
            emptyText = "귀찮은 입력은 AI가 대신하고 있어요.."
        default:
            emptyText = "오늘의 음식 사진을 추가해보세요."
        }
        emptyLabel.setText(emptyText, style: .p14)
    }

    private func showCardState() {
        collectionView.isHidden = false
        pageControl.isHidden = cardItems.count <= 1
        emptyStateView.isHidden = true
        editButton.isHidden = false

        pageControl.numberOfPages = cardItems.count
        pageControl.currentPage = 0

        collectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func pageControlChanged() {
        let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    @objc private func editTapped() {
        editTapSubject.send(mealType)
    }
}

// MARK: - UICollectionViewDataSource

extension MealSectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cardItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DetailFoodCardCell.reuseIdentifier,
            for: indexPath
        ) as? DetailFoodCardCell else {
            return UICollectionViewCell()
        }

        let cardItem = cardItems[indexPath.item]
        cell.configure(with: cardItem.record, imageURL: cardItem.imageURL)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MealSectionView: UICollectionViewDelegate {}
