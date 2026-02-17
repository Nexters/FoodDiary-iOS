//
//  EditImageSectionView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

/// 이미지 편집 섹션 (가로 스크롤 CollectionView)
final class EditImageSectionView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cellSize: CGFloat = 150
        static let cellSpacing: CGFloat = 8
        static let sectionInset: CGFloat = 20
    }

    // MARK: - Publishers

    var addImageTapPublisher: AnyPublisher<Void, Never> {
        addImageTapSubject.eraseToAnyPublisher()
    }

    var removeExistingImagePublisher: AnyPublisher<Int, Never> {
        removeExistingImageSubject.eraseToAnyPublisher()
    }

    var removeNewImagePublisher: AnyPublisher<Int, Never> {
        removeNewImageSubject.eraseToAnyPublisher()
    }

    private let addImageTapSubject = PassthroughSubject<Void, Never>()
    private let removeExistingImageSubject = PassthroughSubject<Int, Never>()
    private let removeNewImageSubject = PassthroughSubject<Int, Never>()

    // MARK: - State

    private var existingImageURLs: [URL] = []
    private var newImages: [UIImage] = []

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Constants.cellSize, height: Constants.cellSize)
        layout.minimumInteritemSpacing = Constants.cellSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0, left: Constants.sectionInset,
            bottom: 0, right: Constants.sectionInset
        )

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(AddImageCell.self, forCellWithReuseIdentifier: AddImageCell.reuseIdentifier)
        cv.register(EditImageCell.self, forCellWithReuseIdentifier: EditImageCell.reuseIdentifier)
        return cv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(collectionView)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(Constants.cellSize)
        }
    }

    // MARK: - Public Methods

    func configure(existingImageURLs: [URL], newImages: [UIImage]) {
        self.existingImageURLs = existingImageURLs
        self.newImages = newImages
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension EditImageSectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1 + existingImageURLs.count + newImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AddImageCell.reuseIdentifier,
                for: indexPath
            ) as? AddImageCell else {
                return UICollectionViewCell()
            }
            return cell
        }

        let adjustedIndex = indexPath.item - 1

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EditImageCell.reuseIdentifier,
            for: indexPath
        ) as? EditImageCell else {
            return UICollectionViewCell()
        }

        if adjustedIndex < existingImageURLs.count {
            let url = existingImageURLs[adjustedIndex]
            cell.configure(with: url)
            cell.onDeleteTapped = { [weak self] in
                self?.removeExistingImageSubject.send(adjustedIndex)
            }
        } else {
            let newImageIndex = adjustedIndex - existingImageURLs.count
            let image = newImages[newImageIndex]
            cell.configure(with: image)
            cell.onDeleteTapped = { [weak self] in
                self?.removeNewImageSubject.send(newImageIndex)
            }
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension EditImageSectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            addImageTapSubject.send()
        }
    }
}
