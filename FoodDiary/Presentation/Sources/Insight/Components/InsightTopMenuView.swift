//
//  InsightTopMenuView.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

final class InsightTopMenuView: UIView {

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let menuLabel = UILabel()

    // MARK: - Init

    init(topMenu: TopMenu) {
        super.init(frame: .zero)
        setupUI(topMenu: topMenu)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(topMenu: TopMenu) {
        backgroundColor = .sd900
        layer.cornerRadius = 16
        clipsToBounds = true

        titleLabel.setText("🏆 최다 메뉴", style: .hd18)
        addSubview(titleLabel)

        menuLabel.setText(
            "\(topMenu.name) — \(topMenu.count)회 기록",
            style: .p15,
            color: .gray050
        )
        menuLabel.numberOfLines = 0
        addSubview(menuLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        menuLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
