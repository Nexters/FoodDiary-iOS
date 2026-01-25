//
//  ImagePickerViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

// MARK: - Picker Result

// MARK: - ImagePickerViewController

/// 이미지를 선택하는 UI를 제공합니다.
public final class ImagePickerViewController<
    Asset: ImageAssetable,
    ImageProvider: ImageProviding
>:
    UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - Public Publisher

    /// 피커 결과 Publisher
    public var resultPublisher: AnyPublisher<FoodImagePickerResult<Asset>, Never> {
        resultSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let resultSubject = PassthroughSubject<FoodImagePickerResult<Asset>, Never>()
    private var cancellables = Set<AnyCancellable>()

    private let photos: [FoodPhoto<Asset>]
    private let imageProvider: ImageProvider
    private let configuration: ImagePickerConfiguration

    // MARK: - State

    private var selectedPhotoIds: Set<String> = []

    // MARK: - UI Components

    private let navigationBar = ImagePickerNavigationBar()

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
            SelectableImageCell.self,
            forCellWithReuseIdentifier: SelectableImageCell.reuseIdentifier
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

    // MARK: - Initialization

    public init(
        photos: [FoodPhoto<Asset>],
        imageProvider: ImageProvider,
        configuration: ImagePickerConfiguration = .default
    ) {
        self.photos = photos
        self.imageProvider = imageProvider
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .coverVertical
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
        setupBindings()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.background.color
        
        view.addSubview(navigationBar)
        view.addSubview(collectionView)
        view.addSubview(confirmButton)
    }

    private func setupConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-16)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(50)
        }
    }

    private func setupBindings() {
        navigationBar.closeTapPublisher
            .sink { [weak self] in
                self?.handleCancel()
            }
            .store(in: &cancellables)
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
        if let cell = collectionView.cellForItem(at: indexPath) as? SelectableImageCell {
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
        let selectedPhotos = photos.filter { selectedPhotoIds.contains($0.id) }
        resultSubject.send(.selected(selectedPhotos))
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
            withReuseIdentifier: SelectableImageCell.reuseIdentifier,
            for: indexPath
        ) as! SelectableImageCell

        let photo = photos[indexPath.item]
        let isSelected = selectedPhotoIds.contains(photo.id)

        cell.configure(
            isSelected: isSelected,
            configuration: configuration,
            showsProbabilityLabel: configuration.showsFoodProbability
        )

        if configuration.showsFoodProbability {
            cell.setFoodProbability(photo.foodProbability)
        }

        // 이미지 로딩(비동기)
        loadImage(for: photo, cell: cell, at: indexPath)

        return cell
    }

    private func loadImage(for photo: FoodPhoto<Asset>, cell: SelectableImageCell, at indexPath: IndexPath) {
        Task {
            do {
                let image = try await imageProvider.loadImage(
                    for: photo.id,
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
