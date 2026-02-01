//
//  BadgeView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 범용 배지 뷰
final class BadgeView: UIView {

    // MARK: - UI Components

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    init(text: String, backgroundColor: UIColor, textColor: UIColor = .white) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        self.backgroundColor = backgroundColor
        label.setText(text, style: .p10, color: textColor)
    }

    convenience init(genre: FoodGenre) {
        self.init(text: genre.displayName, backgroundColor: DesignSystemAsset.primary.color)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = 12
        clipsToBounds = true
        addSubview(label)
    }

    private func setupConstraints() {
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
    }

}
