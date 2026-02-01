//
//  MealTypeBadgeView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 식사 타입 배지 (중식, 석식 등)
final class MealTypeBadgeView: UIView {

    // MARK: - UI Components

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
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
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        layer.cornerRadius = 12
        clipsToBounds = true
        addSubview(label)
    }

    private func setupConstraints() {
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
    }

    // MARK: - Configuration

    func configure(with mealType: MealType) {
        label.setText(mealType.displayName, style: .p12, color: .white)
    }
}
