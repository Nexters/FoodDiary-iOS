//
//  ImagePickerSectionHeaderView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

final class ImagePickerSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "ImagePickerSectionHeaderView"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.setText(title, style: .hd18, color: .white)
    }
}
