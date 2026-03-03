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

    private enum ImageItem {
        case existingImage(index: Int, url: URL)
        case newImage(index: Int, image: UIImage)
    }

    // MARK: - Publishers

    var removeExistingImagePublisher: AnyPublisher<Int, Never> {
        removeExistingImageSubject.eraseToAnyPublisher()
    }

    var removeNewImagePublisher: AnyPublisher<Int, Never> {
        removeNewImageSubject.eraseToAnyPublisher()
    }

    private let removeExistingImageSubject = PassthroughSubject<Int, Never>()
    private let removeNewImageSubject = PassthroughSubject<Int, Never>()

    // MARK: - State

    private var existingImageURLs: [URL] = []
    private var newImages: [UIImage] = []

    private var items: [ImageItem] {
        var result: [ImageItem] = []
        result += existingImageURLs.enumerated().map { .existingImage(index: $0.offset, url: $0.element) }
        result += newImages.enumerated().map { .newImage(index: $0.offset, image: $0.element) }
        return result
    }

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
        cv.dataSource = self
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
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch items[indexPath.item] {
        case .existingImage(let index, let url):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EditImageCell.reuseIdentifier,
                for: indexPath
            ) as? EditImageCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: url)
            cell.onDeleteTapped = { [weak self] in
                self?.removeExistingImageSubject.send(index)
            }
            return cell

        case .newImage(let index, let image):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EditImageCell.reuseIdentifier,
                for: indexPath
            ) as? EditImageCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: image)
            cell.onDeleteTapped = { [weak self] in
                self?.removeNewImageSubject.send(index)
            }
            return cell
        }
    }
}

