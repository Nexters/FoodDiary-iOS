//
//  PillBadgeView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 시간/지역 표시용 알약형 배지 뷰
final class PillBadgeView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 14
        static let verticalInset: CGFloat = 6
        static let horizontalInset: CGFloat = 12
    }

    // MARK: - UI Components

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    init(text: String) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        label.setText(text, style: .p10, color: .white)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .detailBadgeBackground
        layer.cornerRadius = Constants.cornerRadius
        clipsToBounds = true
        addSubview(label)
    }

    private func setupConstraints() {
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: Constants.verticalInset,
                    left: Constants.horizontalInset,
                    bottom: Constants.verticalInset,
                    right: Constants.horizontalInset
                ))
        }
    }
}
