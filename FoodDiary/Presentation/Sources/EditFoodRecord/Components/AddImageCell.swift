//
//  AddImageCell.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 이미지 추가(+) 셀 (대시 보더)
final class AddImageCell: UICollectionViewCell {

    static let reuseIdentifier = "AddImageCell"

    // MARK: - UI Components

    private let plusImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "plus")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .light))
        iv.tintColor = .gray400
        iv.contentMode = .center
        return iv
    }()

    private let dashedBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.gray600.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineDashPattern = [6, 4]
        layer.lineWidth = 1
        return layer
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

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedBorderLayer.path = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: 12
        ).cgPath
        dashedBorderLayer.frame = contentView.bounds
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.layer.addSublayer(dashedBorderLayer)
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        contentView.addSubview(plusImageView)
    }

    private func setupConstraints() {
        plusImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
