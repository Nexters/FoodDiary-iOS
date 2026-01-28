//
//  ImagePickerCell.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 선택 가능한 이미지 셀
public final class ImagePickerCell: UICollectionViewCell {
    public static let reuseIdentifier = "ImagePickerCell"

    // MARK: - UI Components

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let selectionBorderView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 12
        view.isUserInteractionEnabled = false
        return view
    }()

    // MARK: - Properties

    private var configuration: ImagePickerConfiguration = .default
    private var isSelectedState: Bool = false

    // MARK: - Initialization

    public override init(frame: CGRect) {
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
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(selectionBorderView)
        contentView.addSubview(checkmarkImageView)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionBorderView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        checkmarkImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(8)
            $0.size.equalTo(20)
        }
    }

    // MARK: - Configuration

    /// 셀 설정
    /// - Parameters:
    ///   - isSelected: 선택 상태
    ///   - configuration: 피커 설정
    public func configure(
        isSelected: Bool,
        configuration: ImagePickerConfiguration = .default
    ) {
        self.configuration = configuration
        self.isSelectedState = isSelected
        updateSelectionAppearance()
    }

    /// 이미지 설정 (비동기 로딩용)
    public func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    /// 선택 상태 업데이트
    public func setSelected(_ selected: Bool) {
        isSelectedState = selected
        updateSelectionAppearance()
    }

    // MARK: - Private Methods

    private func updateSelectionAppearance() {
        if isSelectedState {
            // 선택됨
            selectionBorderView.layer.borderColor = configuration.primaryColor.cgColor
            selectionBorderView.isHidden = false
            checkmarkImageView.image = DesignSystemAsset.checkmarkSelected.image
        } else {
            // 미선택
            selectionBorderView.isHidden = true
            checkmarkImageView.image = DesignSystemAsset.checkmarkUnSelected.image
        }
    }

    // MARK: - Reuse

    public override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        isSelectedState = false
        updateSelectionAppearance()
    }
}
