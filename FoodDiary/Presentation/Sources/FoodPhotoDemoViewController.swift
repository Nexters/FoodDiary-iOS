//
//  FoodPhotoDemoViewController.swift
//  Presentation
//
//  Created by Claude on 1/21/26.
//

import UIKit
import Photos
import Data
import Domain

public final class FoodPhotoDemoViewController: UIViewController {

    // MARK: - UI Components

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "준비 중..."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private let fetchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("음식 사진 가져오기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties

    private var sortedDates: [Date] = []
    private var photosByDate: [Date: [FoodPhoto]] = [:]
    private lazy var photoFetcher: FoodPhotoFetcher<PHPhotoLibraryFetcher, TFLiteFoodClassifier>? = {
        do {
            let photoLibrary = PHPhotoLibraryFetcher()

            // Data 모듈의 번들을 명시적으로 지정
            guard let dataBundle = Bundle(identifier: "com.fooddiary.data") else {
                print("❌ Failed to find Data bundle")
                return nil
            }

            let classifier = try TFLiteFoodClassifier(
                modelName: "food_classifier",
                modelType: "tflite",
                bundle: dataBundle
            )

            return FoodPhotoFetcher(
                photoLibrary: photoLibrary,
                foodClassifier: classifier
            )
        } catch {
            print("❌ Failed to initialize: \(error)")
            return nil
        }
    }()

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupCollectionView()
        checkPhotoLibraryPermission()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "음식 사진 데모"
        view.backgroundColor = .systemBackground

        view.addSubview(statusLabel)
        view.addSubview(fetchButton)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        fetchButton.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        fetchButton.addTarget(self, action: #selector(fetchButtonTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            fetchButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            fetchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fetchButton.widthAnchor.constraint(equalToConstant: 250),
            fetchButton.heightAnchor.constraint(equalToConstant: 50),

            collectionView.topAnchor.constraint(equalTo: fetchButton.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FoodPhotoCell.self, forCellWithReuseIdentifier: "FoodPhotoCell")
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeaderView"
        )
    }

    // MARK: - Permission

    private func checkPhotoLibraryPermission() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

            await MainActor.run {
                switch status {
                case .authorized, .limited:
                    statusLabel.text = "✅ 권한 승인됨. 버튼을 눌러 음식 사진을 가져오세요."
                    fetchButton.isEnabled = true
                case .denied, .restricted:
                    statusLabel.text = "⚠️ 사진 라이브러리 접근 권한이 필요합니다."
                    fetchButton.isEnabled = false
                case .notDetermined:
                    statusLabel.text = "❓ 권한 상태 미확인"
                    fetchButton.isEnabled = false
                @unknown default:
                    statusLabel.text = "❓ 알 수 없는 권한 상태"
                    fetchButton.isEnabled = false
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func fetchButtonTapped() {
        Task {
            await fetchFoodPhotos()
        }
    }

    private func fetchFoodPhotos() async {
        guard let fetcher = photoFetcher else {
            await MainActor.run {
                statusLabel.text = "❌ 초기화 실패"
            }
            return
        }

        await MainActor.run {
            activityIndicator.startAnimating()
            fetchButton.isEnabled = false
            statusLabel.text = "🔄 음식 사진 분석 중... (병렬 처리)"
        }

        let startTime = Date()

        do {
            // 최근 30일간의 사진 가져오기
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

            let result = try await fetcher.fetchFoodPhotos(from: startDate, to: endDate)

            let duration = Date().timeIntervalSince(startTime)
            let totalPhotos = result.values.reduce(0) { $0 + $1.count }

            await MainActor.run {
                self.photosByDate = result
                self.sortedDates = result.keys.sorted(by: >)
                self.collectionView.reloadData()
                self.activityIndicator.stopAnimating()
                self.fetchButton.isEnabled = true
                self.statusLabel.text = """
                ✅ 완료!
                \(result.count)개 날짜에서 \(totalPhotos)장의 음식 사진 발견
                소요 시간: \(String(format: "%.2f", duration))초
                """
            }
        } catch {
            await MainActor.run {
                self.activityIndicator.stopAnimating()
                self.fetchButton.isEnabled = true
                self.statusLabel.text = "❌ 오류: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension FoodPhotoDemoViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sortedDates.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let date = sortedDates[section]
        return photosByDate[date]?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FoodPhotoCell", for: indexPath) as! FoodPhotoCell

        let date = sortedDates[indexPath.section]
        if let photos = photosByDate[date] {
            cell.configure(with: photos[indexPath.item])
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionHeaderView",
            for: indexPath
        ) as! SectionHeaderView

        let date = sortedDates[indexPath.section]
        let photoCount = photosByDate[date]?.count ?? 0
        header.configure(date: date, photoCount: photoCount)

        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FoodPhotoDemoViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 * 2 + 8 * 2 // section padding + spacing
        let availableWidth = collectionView.bounds.width - padding
        let itemWidth = availableWidth / 3
        return CGSize(width: itemWidth, height: itemWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
}

// MARK: - FoodPhotoCell

private class FoodPhotoCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        return iv
    }()

    private let confidenceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(confidenceLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            confidenceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            confidenceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            confidenceLabel.widthAnchor.constraint(equalToConstant: 40),
            confidenceLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
    }

    func configure(with foodPhoto: FoodPhoto) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        manager.requestImage(
            for: foodPhoto.asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }

        let percentage = Int(foodPhoto.foodProbability * 100)
        confidenceLabel.text = "\(percentage)%"
    }
}

// MARK: - SectionHeaderView

private class SectionHeaderView: UICollectionReusableView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(date: Date, photoCount: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        titleLabel.text = "\(formatter.string(from: date)) - \(photoCount)장"
    }
}
