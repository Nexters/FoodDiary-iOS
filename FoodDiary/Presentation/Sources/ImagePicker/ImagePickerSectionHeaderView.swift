//
//  ImagePickerSectionHeaderView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

final class ImagePickerSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "ImagePickerSectionHeaderView"

    private let guideLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(guideLabel)
        addSubview(titleLabel)

        guideLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, guideText: String? = nil) {
        titleLabel.setText(title, style: .hd16, color: .white)

        if let guideText {
            guideLabel.setText(guideText, style: .p14, color: .gray400)
            guideLabel.isHidden = false
        } else {
            guideLabel.isHidden = true
        }
    }
}
