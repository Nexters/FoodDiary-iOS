//
//  InsightCategoryStatsView.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

final class InsightCategoryStatsView: UIView {

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let currentMonthLabel = UILabel()
    private let previousMonthLabel = UILabel()

    // MARK: - Init

    init(categoryStats: CategoryStats) {
        super.init(frame: .zero)
        setupUI(categoryStats: categoryStats)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(categoryStats: CategoryStats) {
        backgroundColor = .sd900
        layer.cornerRadius = 16
        clipsToBounds = true

        titleLabel.setText("🍽️ 카테고리 분석", style: .hd18)
        addSubview(titleLabel)

        let current = categoryStats.currentMonth
        currentMonthLabel.setText(
            "이번 달 최다: \(current.topCategory) (\(current.count)회)",
            style: .p15,
            color: .gray050
        )
        addSubview(currentMonthLabel)

        let previous = categoryStats.previousMonth
        previousMonthLabel.setText(
            "지난 달 최다: \(previous.topCategory) (\(previous.count)회)",
            style: .p14,
            color: .gray300
        )
        addSubview(previousMonthLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        currentMonthLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        previousMonthLabel.snp.makeConstraints {
            $0.top.equalTo(currentMonthLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
