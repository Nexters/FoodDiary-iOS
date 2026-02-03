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
    UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - Public Publisher

    /// 피커 결과 Publisher
    public var resultPublisher: AnyPublisher<ImagePickerResult<Asset>, Never> {
        resultSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let resultSubject = PassthroughSubject<ImagePickerResult<Asset>, Never>()
    private var cancellables = Set<AnyCancellable>()

    private let photos: [Asset]
    private let preselectedIds: Set<String>
    private let imageProvider: ImageProvider
    private let configuration: ImagePickerConfiguration

    // MARK: - State

    private var selectedPhotoIds: Set<String> = []

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.allowsMultipleSelection = true
        cv.delegate = self
        cv.dataSource = self
        cv.register(
            ImagePickerCell.self,
            forCellWithReuseIdentifier: ImagePickerCell.reuseIdentifier
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

        let label = UILabel()
        label.setText("이 날짜에 찍은 사진이 없어요", style: .hd18, color: .gray400)
        label.textColor = .gray400
        label.textAlignment = .center

        container.addSubview(label)
        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        return container
    }()

    // MARK: - Initialization

    /// 이미지 피커 초기화
    /// - Parameters:
    ///   - photos: 표시할 사진 목록
    ///   - preselectedIds: 미리 선택될 사진 ID 집합
    ///   - imageProvider: 이미지 로딩 제공자
    ///   - configuration: 피커 설정
    public init(
        photos: [Asset],
        preselectedIds: Set<String> = [],
        imageProvider: ImageProvider,
        configuration: ImagePickerConfiguration = .default
    ) {
        self.photos = photos
        self.preselectedIds = preselectedIds
        self.imageProvider = imageProvider
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        applyPreselection()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

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
        for photo in photos where preselectedIds.contains(photo.id) {
            // 최대 선택 수 확인
            if let maxCount = configuration.maxSelectionCount,
               selectedPhotoIds.count >= maxCount {
                break
            }
            selectedPhotoIds.insert(photo.id)
        }
        updateConfirmButton()
    }

    // MARK: - Selection

    private func toggleSelection(at indexPath: IndexPath) {
        let photo = photos[indexPath.item]

        if selectedPhotoIds.contains(photo.id) {
            selectedPhotoIds.remove(photo.id)
        } else {
            // 최대 선택 수 확인
            if let maxCount = configuration.maxSelectionCount,
               selectedPhotoIds.count >= maxCount {
                return
            }
            selectedPhotoIds.insert(photo.id)
        }

        // 셀 업데이트
        if let cell = collectionView.cellForItem(at: indexPath) as? ImagePickerCell {
            cell.setSelected(selectedPhotoIds.contains(photo.id))
        }

        updateConfirmButton()
    }

    private func updateConfirmButton() {
        let count = selectedPhotoIds.count
        confirmButton.isEnabled = count > 0
        let title = count > 0 ? "\(count)장 올리기" : configuration.confirmButtonTitle
        confirmButton.setTitle(title, for: .normal)
    }

    // MARK: - Actions

    @objc private func confirmButtonTapped() {
        let selectedAssets = photos.filter { selectedPhotoIds.contains($0.id) }
        resultSubject.send(.selected(selectedAssets))
    }

    private func handleCancel() {
        resultSubject.send(.cancelled)
    }

    // MARK: - UICollectionViewDataSource

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImagePickerCell.reuseIdentifier,
            for: indexPath
        ) as! ImagePickerCell

        let photo = photos[indexPath.item]
        let isSelected = selectedPhotoIds.contains(photo.id)

        cell.configure(
            isSelected: isSelected,
            configuration: configuration
        )

        // 이미지 로딩(비동기)
        loadImage(for: photo, cell: cell, at: indexPath)

        return cell
    }

    private func loadImage(for photo: Asset, cell: ImagePickerCell, at indexPath: IndexPath) {
        Task {
            do {
                let image = try await imageProvider.loadImage(
                    for: photo,
                    targetSize: CGSize(width: 300, height: 300)
                )
                await MainActor.run {
                    // 셀이 여전히 같은 indexPath에 있는지 확인
                    guard let currentIndexPath = self.collectionView.indexPath(for: cell),
                          currentIndexPath == indexPath else {
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

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        toggleSelection(at: indexPath)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let padding: CGFloat = 16 * 2 + 8 * 2 // section padding + spacing
        let availableWidth = collectionView.bounds.width - padding
        let itemWidth = availableWidth / 3
        return CGSize(width: itemWidth, height: itemWidth)
    }
}
