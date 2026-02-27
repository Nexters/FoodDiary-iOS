//
//  ImagePickerViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

// MARK: - ImagePickerViewController

/// 음식 사진을 선택할 수 있는 커스텀 이미지 피커 뷰 컨트롤러입니다.
///
/// ## Overview
/// `ImagePickerViewController`는 `FoodImageAsset` 배열을 받아 그리드 형태로 표시하고,
/// 사용자가 사진을 선택하면 `resultPublisher`를 통해 결과를 전달합니다.
///
/// ## Usage
/// ```swift
/// // 1. 피커 생성
/// let picker = ImagePickerViewController(
///     photos: foodPhotos,
///     imageProvider: myImageProvider,
///     configuration: .default
/// )
///
/// // 2. 결과 구독
/// picker.resultPublisher
///     .sink { result in
///         switch result {
///         case .selected(let photos):
///             // 선택된 사진 처리
///             self.dismiss(animated: true)
///         case .cancelled:
///             // 취소 처리
///             self.dismiss(animated: true)
///         }
///     }
///     .store(in: &cancellables)
///
/// // 3. 피커 표시
/// present(picker, animated: true)
/// ```
///
/// ## Configuration
/// `ImagePickerConfiguration`을 통해 다음 항목을 커스터마이징할 수 있습니다:
/// - `primaryColor`: 선택 테두리 및 버튼 색상
/// - `maxSelectionCount`: 최대 선택 가능 수 (nil이면 무제한)
/// - `confirmButtonTitle`: 확인 버튼 텍스트
///
public final class ImagePickerViewController<
    Asset: ImageAssetable,
    ImageProvider: RenderableImageRepository<Asset>
>:
    UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
{

    // MARK: - Section

    private enum PhotoSection: Int, CaseIterable {
        case food
        case all

        var headerTitle: String {
            switch self {
            case .food: return "음식"
            case .all: return "전체"
            }
        }
    }

    // MARK: - SelectAll Button State

    private enum SelectAllButtonState {
        case selectAllFood
        case deselectAll

        var title: String {
            switch self {
            case .selectAllFood: return "모두선택"
            case .deselectAll: return "모두해제"
            }
        }
    }

    // MARK: - Public Publisher

    /// 피커 결과 Publisher
    public var resultPublisher: AnyPublisher<ImagePickerResult<Asset>, Never> {
        resultSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let resultSubject = PassthroughSubject<ImagePickerResult<Asset>, Never>()
    private var cancellables = Set<AnyCancellable>()

    private let photos: [Asset]
    private let preselectedFoodPhotoIds: Set<String>
    private let imageProvider: ImageProvider
    private let configuration: ImagePickerConfiguration
    // preselected된 사진은 food/all 양쪽 섹션에 나타날 수 있어, id 기준 인덱스를 캐싱한다.
    private let foodPhotos: [Asset]
    private let indexPathsByPhotoId: [String: [IndexPath]]

    // MARK: - State

    private var selectedPhotoIds: Set<String> = []

    // MARK: - Computed Properties

    private func photosInSection(_ section: PhotoSection) -> [Asset] {
        switch section {
        case .food: return foodPhotos
        case .all: return photos
        }
    }

    private var selectAllButtonState: SelectAllButtonState {
        let food = foodPhotos
        guard !food.isEmpty else { return .selectAllFood }
        return food.allSatisfy { selectedPhotoIds.contains($0.id) } ? .deselectAll : .selectAllFood
    }

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.allowsMultipleSelection = true
        cv.delegate = self
        cv.dataSource = self
        cv.register(
            ImagePickerCell.self,
            forCellWithReuseIdentifier: ImagePickerCell.reuseIdentifier
        )
        cv.register(
            ImagePickerSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ImagePickerSectionHeaderView.reuseIdentifier
        )
        return cv
    }()

    private lazy var confirmButton: MumukPrimaryButton = {
        let button = MumukPrimaryButton()
        button.configure(
            title: configuration.confirmButtonTitle,
            primaryColor: configuration.primaryColor,
            buttonTextColor: configuration.buttonTextColor,
            buttonDisabledColor: configuration.buttonDisabledColor
        )
        button.isEnabled = false
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()

    private let emptyView: UIView = {
        let container = UIView()
        container.isHidden = true

        let imageView = UIImageView(image: DesignSystemAsset.emptyImage.image)
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(210)
        }

        let label = UILabel()
        label.setText("오늘은 촬영된 사진이 없어요", style: .p12, color: .gray050)
        label.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center

        container.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        return container
    }()

    // MARK: - Initialization

    /// 이미지 피커 초기화
    /// - Parameters:
    ///   - photos: 표시할 사진 목록
    ///   - preselectedFoodPhotoIds: 미리 선택될 음식 사진 ID 집합
    ///   - imageProvider: 이미지 로딩 제공자
    ///   - configuration: 피커 설정
    public init(
        photos: [Asset],
        preselectedFoodPhotoIds: Set<String> = [],
        imageProvider: ImageProvider,
        configuration: ImagePickerConfiguration = .default
    ) {
        // 매 접근마다 filter하지 않도록 음식 섹션 데이터를 1회 계산해 둔다.
        let foodPhotos = photos.filter { preselectedFoodPhotoIds.contains($0.id) }

        self.photos = photos
        self.preselectedFoodPhotoIds = preselectedFoodPhotoIds
        self.imageProvider = imageProvider
        self.configuration = configuration
        self.foodPhotos = foodPhotos
        self.indexPathsByPhotoId = Self.makeIndexPathsByPhotoId(
            allPhotos: photos,
            foodPhotos: foodPhotos
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupConstraints()
        applyPreselection()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            resultSubject.send(.cancelled)
        }
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        let selectAllButton = UIBarButtonItem(
            title: selectAllButtonState.title,
            style: .plain,
            target: self,
            action: #selector(selectAllButtonTapped)
        )
        selectAllButton.tintColor = .white
        navigationItem.rightBarButtonItem = selectAllButton
    }

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color

        view.addSubview(collectionView)
        view.addSubview(emptyView)
        view.addSubview(confirmButton)

        emptyView.isHidden = !photos.isEmpty
        collectionView.isHidden = photos.isEmpty
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-16)
        }

        emptyView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-16)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(50)
        }
    }

    private func applyPreselection() {
        for photo in photos where preselectedFoodPhotoIds.contains(photo.id) {
            if let maxCount = configuration.maxSelectionCount,
                selectedPhotoIds.count >= maxCount
            {
                break
            }
            selectedPhotoIds.insert(photo.id)
        }
        updateUI()
    }

    // MARK: - Selection

    private func toggleSelection(at indexPath: IndexPath) {
        guard let section = PhotoSection(rawValue: indexPath.section) else { return }
        let photo = photosInSection(section)[indexPath.item]

        if selectedPhotoIds.contains(photo.id) {
            selectedPhotoIds.remove(photo.id)
        } else {
            if let maxCount = configuration.maxSelectionCount,
                selectedPhotoIds.count >= maxCount
            {
                return
            }
            selectedPhotoIds.insert(photo.id)
        }

        // 같은 사진이 양쪽 섹션에 동시에 보일 수 있어, 매핑된 셀을 함께 갱신한다.
        let affectedIndexPaths = indexPathsByPhotoId[photo.id] ?? [indexPath]
        collectionView.reloadItems(at: affectedIndexPaths)

        updateUI()
    }

    private static func makeIndexPathsByPhotoId(
        allPhotos: [Asset],
        foodPhotos: [Asset]
    ) -> [String: [IndexPath]] {
        // photo id -> [food 섹션 indexPath, all 섹션 indexPath]
        var indexPathsById: [String: [IndexPath]] = [:]

        for (item, photo) in foodPhotos.enumerated() {
            indexPathsById[photo.id, default: []].append(
                IndexPath(item: item, section: PhotoSection.food.rawValue)
            )
        }

        for (item, photo) in allPhotos.enumerated() {
            indexPathsById[photo.id, default: []].append(
                IndexPath(item: item, section: PhotoSection.all.rawValue)
            )
        }

        return indexPathsById
    }

    private func updateUI() {
        let count = selectedPhotoIds.count
        confirmButton.isEnabled = count > 0
        let title = count > 0 ? "선택하기(\(count))" : configuration.confirmButtonTitle
        confirmButton.setTitle(title, for: .normal)
        navigationItem.rightBarButtonItem?.title = selectAllButtonState.title
    }

    // MARK: - Actions

    @objc private func selectAllButtonTapped() {
        switch selectAllButtonState {
        case .selectAllFood:
            for photo in foodPhotos {
                if let maxCount = configuration.maxSelectionCount,
                    selectedPhotoIds.count >= maxCount
                {
                    break
                }
                selectedPhotoIds.insert(photo.id)
            }
        case .deselectAll:
            selectedPhotoIds.removeAll()
        }
        updateVisibleCellsSelection()
        updateUI()
    }

    private func updateVisibleCellsSelection() {
        for cell in collectionView.visibleCells {
            guard let imageCell = cell as? ImagePickerCell,
                let indexPath = collectionView.indexPath(for: cell),
                let section = PhotoSection(rawValue: indexPath.section)
            else { continue }
            let photo = photosInSection(section)[indexPath.item]
            imageCell.setSelected(selectedPhotoIds.contains(photo.id))
        }
    }

    @objc private func confirmButtonTapped() {
        let selectedAssets = photos.filter { selectedPhotoIds.contains($0.id) }
        resultSubject.send(.selected(selectedAssets))
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return PhotoSection.allCases.count
    }

    public func collectionView(
        _ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        guard let photoSection = PhotoSection(rawValue: section) else { return 0 }
        return photosInSection(photoSection).count
    }

    public func collectionView(
        _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: ImagePickerCell.reuseIdentifier,
                for: indexPath
            ) as! ImagePickerCell

        guard let photoSection = PhotoSection(rawValue: indexPath.section) else { return cell }
        let photo = photosInSection(photoSection)[indexPath.item]
        let isSelected = selectedPhotoIds.contains(photo.id)

        cell.configure(
            isSelected: isSelected,
            configuration: configuration
        )

        loadImage(for: photo, cell: cell, at: indexPath)

        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ImagePickerSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? ImagePickerSectionHeaderView,
            let photoSection = PhotoSection(rawValue: indexPath.section)
        else {
            return UICollectionReusableView()
        }
        let guideText: String? =
            photoSection == .food
            ? configuration.maxSelectionCount.map { "\($0)장까지 선택할 수 있어요." }
            : nil
        header.configure(title: photoSection.headerTitle, guideText: guideText)
        return header
    }

    private func loadImage(for photo: Asset, cell: ImagePickerCell, at indexPath: IndexPath) {
        Task {
            do {
                let image = try await imageProvider.loadImage(
                    for: photo,
                    targetSize: CGSize(width: 300, height: 300)
                )
                await MainActor.run {
                    guard let currentIndexPath = self.collectionView.indexPath(for: cell),
                        currentIndexPath == indexPath
                    else {
                        return
                    }
                    cell.setImage(image)
                }
            } catch {
                // 이미지 로드 실패 시 무시
            }
        }
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(
        _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: false)
        toggleSelection(at: indexPath)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let padding: CGFloat = 16 * 2 + 8 * 2
        let availableWidth = collectionView.bounds.width - padding
        let itemWidth = availableWidth / 3
        return CGSize(width: itemWidth, height: itemWidth)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard let photoSection = PhotoSection(rawValue: section),
            !photosInSection(photoSection).isEmpty
        else {
            return .zero
        }
        let height: CGFloat =
            photoSection == .food && configuration.maxSelectionCount != nil ? 72 : 44
        return CGSize(width: collectionView.bounds.width, height: height)
    }
}
