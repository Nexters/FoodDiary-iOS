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
        static let titleTopInset: CGFloat = 42
        static let contentTopInset: CGFloat = 16
        static let horizontalInset: CGFloat = 20
        static let textHorizontalInset: CGFloat = Self.horizontalInset + 10
        static let cardSpacing: CGFloat = 12
        static let pageControlTopSpacing: CGFloat = 8
        static let pageControlHeight: CGFloat = 20
        static let infoTopSpacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 10
        static let hashtagTopSpacing: CGFloat = 16
        static let emptyStateImageSize: CGFloat = 140
        static let emptyCardCornerRadius: CGFloat = 16
        static let emptyLabelTopSpacing: CGFloat = 25
        static let buttonImagePadding: CGFloat = 4
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
    private var currentRecord: FoodRecord?

    // MARK: - UI Components

    // 섹션 제목 (아침 / 점심 / 저녁 / 야식)
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()

    // 섹션 제목 우측 "수정" 버튼 (음식 기록이 있을 때만 노출)
    private let editButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        return button
    }()

    // 카드 캐러셀 + 정보 영역 + 빈 상태 뷰를 감싸는 컨테이너
    private let contentContainerView: UIView = {
        let view = UIView()
        return view
    }()

    // 음식 사진 카드 캐러셀 (좌우 스와이프로 넘김)
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(
            DetailFoodCardCell.self, forCellWithReuseIdentifier: DetailFoodCardCell.reuseIdentifier)
        return cv
    }()

    // 카드 하단 페이지 인디케이터 (카드 2장 이상일 때 노출)
    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .primary
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
        pc.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        return pc
    }()

    // 빈 상태 뷰 (기록 없을 때 일러스트 + 안내 문구)
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    // 빈 상태 카드 (점선 테두리 박스)
    private let emptyCardView: DashedBorderView = {
        let view = DashedBorderView(strokeColor: .gray900)
        view.cornerRadius = Constants.emptyCardCornerRadius
        view.backgroundColor = .sd900
        view.layer.cornerRadius = Constants.emptyCardCornerRadius
        view.clipsToBounds = true
        return view
    }()

    // 빈 상태 일러스트 이미지 (추가 아이콘)
    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.add.image
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // 빈 상태 안내 문구 ("오늘의 음식 사진을 추가해보세요." 등)
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 음식 사진을 추가해보세요."
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.textAlignment = .center
        return label
    }()

    // 카드 하단 정보 영역 (식당명, 복사/공유 버튼, 해시태그)
    private let infoContainerView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    // 식당명 라벨 (예: "식당명")
    private let restaurantNameLabel = UILabel()

    // "복사" 버튼 (아이콘 + 텍스트)
    private let copyButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = DesignSystemAsset.iconCopy.image
            .withRenderingMode(.alwaysTemplate)
        config.imagePadding = Constants.buttonImagePadding
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.tintColor = .white
        return button
    }()

    // "공유" 버튼 (링크 아이콘 + 텍스트)
    private let shareButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "link")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        config.imagePadding = Constants.buttonImagePadding
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.tintColor = .white
        return button
    }()

    // 해시태그 라벨 (예: "#돈까스김밥 #김치볶음밥 #양장피 #고량주")
    private let hashtagLabel = UILabel()

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

        // Info section
        contentContainerView.addSubview(infoContainerView)
        infoContainerView.addSubview(restaurantNameLabel)
        infoContainerView.addSubview(copyButton)
        infoContainerView.addSubview(shareButton)
        infoContainerView.addSubview(hashtagLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.titleTopInset)
            $0.leading.equalToSuperview().offset(Constants.textHorizontalInset)
        }

        editButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-Constants.textHorizontalInset)
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
            $0.top.equalTo(collectionView.snp.bottom).offset(Constants.pageControlTopSpacing)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(Constants.pageControlHeight)
        }

        infoContainerView.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(Constants.infoTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(Constants.textHorizontalInset)
            $0.bottom.equalToSuperview()
        }

        restaurantNameLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }

        shareButton.snp.makeConstraints {
            $0.centerY.equalTo(restaurantNameLabel)
            $0.trailing.equalToSuperview()
        }

        copyButton.snp.makeConstraints {
            $0.centerY.equalTo(restaurantNameLabel)
            $0.trailing.equalTo(shareButton.snp.leading).offset(-Constants.buttonSpacing)
        }

        hashtagLabel.snp.makeConstraints {
            $0.top.equalTo(restaurantNameLabel.snp.bottom).offset(Constants.hashtagTopSpacing)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        emptyCardView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(emptyCardView.snp.width)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(
                -(Constants.emptyLabelTopSpacing / 2)
            )
            $0.size.equalTo(Constants.emptyStateImageSize)
        }

        emptyLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(emptyImageView.snp.bottom).offset(Constants.emptyLabelTopSpacing)
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
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
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
        titleLabel.setText(title, style: .hd20, color: .white)
    }

    private func configureEditButton() {
        let attributed = NSMutableAttributedString(attributedString: Typography.p14.styled("수정", color: .white))
        attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributed.length))
        editButton.setAttributedTitle(attributed, for: .normal)
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
        infoContainerView.isHidden = true
        emptyStateView.isHidden = false
        editButton.isHidden = true
        currentRecord = nil

        let emptyText: String
        switch mealType {
        case .lunch:
            emptyText = "귀찮은 입력은 AI가 대신하고 있어요.."
        default:
            emptyText = "오늘의 음식 사진을 추가해보세요."
        }
        emptyLabel.setText(emptyText, style: .p14, color: .white)
    }

    private func showCardState() {
        collectionView.isHidden = false
        pageControl.isHidden = cardItems.count <= 1
        emptyStateView.isHidden = true
        editButton.isHidden = false

        pageControl.numberOfPages = cardItems.count
        pageControl.currentPage = 0

        collectionView.reloadData()

        if let record = cardItems.first?.record {
            currentRecord = record
            configureInfoSection(with: record)
            infoContainerView.isHidden = false
        }
    }

    private func configureInfoSection(with record: FoodRecord) {
        restaurantNameLabel.setText(record.restaurantName ?? "", style: .hd16, color: .white)

        let copyTitle = Typography.p12.styled("복사", color: .white)
        copyButton.setAttributedTitle(copyTitle, for: .normal)

        let shareTitle = Typography.p12.styled("공유", color: .white)
        shareButton.setAttributedTitle(shareTitle, for: .normal)

        let hashtagText = record.hashtags.map { "#\($0)" }.joined(separator: " ")
        hashtagLabel.setText(hashtagText, style: .p12, color: .white)
        hashtagLabel.isHidden = record.hashtags.isEmpty
    }

    // MARK: - Actions

    @objc private func pageControlChanged() {
        let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    @objc private func editTapped() {
        editTapSubject.send(mealType)
    }

    @objc private func copyTapped() {
        guard let record = currentRecord else { return }
        copyTapSubject.send(record)
    }

    @objc private func shareTapped() {
        guard let record = currentRecord else { return }
        shareTapSubject.send(record)
    }
}

// MARK: - UICollectionViewDataSource

extension MealSectionView: UICollectionViewDataSource {
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
        cell.configure(with: cardItem.record, imageURL: cardItem.imageURL)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MealSectionView: UICollectionViewDelegate {}
