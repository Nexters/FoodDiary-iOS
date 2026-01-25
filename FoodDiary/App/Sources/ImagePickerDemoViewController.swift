//
//  ImagePickerDemoViewController.swift
//  App
//

import Combine
import Data
import DesignSystem
import Domain
import Photos
import Presentation
import UIKit

/// FoodImagePicker 테스트용 데모 ViewController
final class ImagePickerDemoViewController: UIViewController {
    // MARK: - Properties

    private let repository: FoodPhotoFetcher<TFLiteFoodClassifier, PHImageCache>
    private let imageCache: PHImageCache
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "FoodImagePicker 데모"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let openPickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("이미지 피커 열기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = DesignSystemAsset.background.color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    private let selectedCountLabel: UILabel = {
        let label = UILabel()
        label.text = "선택된 사진: 0장"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var selectedPhotosCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.register(SelectedPhotoCell.self, forCellWithReuseIdentifier: "SelectedPhotoCell")
        return cv
    }()

    // MARK: - State

    private var selectedPhotos: [FoodPhoto<PHAsset>] = []

    // MARK: - Initialization

    init(repository: FoodPhotoFetcher<TFLiteFoodClassifier, PHImageCache>, imageCache: PHImageCache) {
        self.repository = repository
        self.imageCache = imageCache
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(openPickerButton)
        view.addSubview(selectedCountLabel)
        view.addSubview(selectedPhotosCollectionView)

        openPickerButton.addTarget(self, action: #selector(openPickerTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        openPickerButton.translatesAutoresizingMaskIntoConstraints = false
        selectedCountLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedPhotosCollectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            openPickerButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            openPickerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openPickerButton.widthAnchor.constraint(equalToConstant: 200),
            openPickerButton.heightAnchor.constraint(equalToConstant: 50),

            selectedCountLabel.topAnchor.constraint(equalTo: openPickerButton.bottomAnchor, constant: 40),
            selectedCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            selectedPhotosCollectionView.topAnchor.constraint(equalTo: selectedCountLabel.bottomAnchor, constant: 16),
            selectedPhotosCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectedPhotosCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectedPhotosCollectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    // MARK: - Actions

    @objc private func openPickerTapped() {
        Task {
            // 권한 체크
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "권한 필요",
                        message: "사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    })
                    alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                    self.present(alert, animated: true)
                }
                return
            }

            do {
                // 최근 7일간의 사진 가져오기
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!

                let result = try await repository.fetchFoodPhotos(from: startDate, to: endDate)

                // 날짜별 딕셔너리를 단일 배열로 평탄화 (음식 확률순)
                let photos = result.values
                    .flatMap { $0 }
                    .sorted { $0.foodProbability > $1.foodProbability }

                print("📷 가져온 사진 수: \(photos.count)")

                await MainActor.run {
                    if photos.isEmpty {
                        let alert = UIAlertController(
                            title: "알림",
                            message: "최근 7일간 사진이 없습니다.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "확인", style: .default))
                        self.present(alert, animated: true)
                        return
                    }
                    presentPicker(with: photos)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "오류",
                        message: "사진 가져오기 실패: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func presentPicker(with photos: [FoodPhoto<PHAsset>]) {
        let imageProvider = PHAssetImageProvider(photos: photos, imageCache: imageCache)
        
        let config: ImagePickerConfiguration = {
            #if DEBUG
            return .debug
            #else
            return .default
            #endif
        }()
        
        let picker = ImagePickerViewController(
            photos: photos,
            imageProvider: imageProvider,
            configuration: config
        )

        picker.resultPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak picker] result in
                guard let self else { return }

                switch result {
                case .selected(let photos):
                    self.selectedPhotos = photos
                    self.selectedCountLabel.text = "선택된 사진: \(photos.count)장"
                    self.selectedPhotosCollectionView.reloadData()

                case .cancelled:
                    break
                }

                picker?.dismiss(animated: true)
            }
            .store(in: &cancellables)

        present(picker, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ImagePickerDemoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedPhotoCell", for: indexPath) as! SelectedPhotoCell
        let photo = selectedPhotos[indexPath.item]

        Task {
            do {
                let image = try await imageCache.requestImage(
                    for: photo.imageAsset,
                    targetSize: CGSize(width: 200, height: 200)
                )
                await MainActor.run {
                    cell.setImage(image)
                }
            } catch {}
        }

        return cell
    }
}

// MARK: - SelectedPhotoCell

private final class SelectedPhotoCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray5
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
