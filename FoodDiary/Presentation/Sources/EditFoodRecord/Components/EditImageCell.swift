//
//  EditImageCell.swift
//  Presentation
//

import DesignSystem
import Kingfisher
import SnapKit
import UIKit

/// 기존 이미지 셀 (x 삭제 버튼 포함)
final class EditImageCell: UICollectionViewCell {

    static let reuseIdentifier = "EditImageCell"

    // MARK: - Properties

    var onDeleteTapped: (() -> Void)?

    // MARK: - UI Components

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .sd800
        return iv
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        button.setImage(
            UIImage(systemName: "xmark.circle.fill")?.withConfiguration(config),
            for: .normal
        )
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        onDeleteTapped = nil
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(deleteButton)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        deleteButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-6)
            $0.size.equalTo(24)
        }
    }

    private func setupActions() {
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(with url: URL) {
        imageView.kf.setImage(with: url)
    }

    func configure(with image: UIImage) {
        imageView.image = image
    }

    // MARK: - Actions

    @objc private func deleteTapped() {
        onDeleteTapped?()
    }
}
