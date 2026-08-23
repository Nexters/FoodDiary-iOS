//
//  InsightCategoryStatsView.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

final class InsightCategoryStatsView: UIView {

    // MARK: - UI Components

    private let descriptionLabel = UILabel()
    private let rankLabel = UILabel()
    private let donutChartView = DonutChartView()

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
        backgroundColor = .detailCardBackground
        layer.cornerRadius = 16
        clipsToBounds = true

        let current = categoryStats.currentMonth
        let previous = categoryStats.previousMonth
        let isSameCategory = current.topCategory == previous.topCategory

        let currentName = FoodGenre(rawValue: current.topCategory)?.displayName ?? current.topCategory
        let previousName = FoodGenre(rawValue: previous.topCategory)?.displayName ?? previous.topCategory

        let descriptionText = isSameCategory ? "왕좌가 유지되었어요." : "왕좌가 바뀌었어요."
        descriptionLabel.setText(descriptionText, style: .hd16, color: .gray850)
        addSubview(descriptionLabel)

        let attributed = NSMutableAttributedString()
        if !isSameCategory {
            attributed.append(Typography.hd16.styled(previousName, color: .blueGradientStart))
            attributed.append(Typography.hd16.styled(" 대신 ", color: .gray850))
        }
        attributed.append(Typography.hd16.styled(currentName, color: .primary))
        attributed.append(Typography.hd16.styled("이 1등이에요.", color: .gray850))
        rankLabel.attributedText = attributed
        addSubview(rankLabel)

        donutChartView.innerRadiusRatio = 0.3
        donutChartView.separatorColor = .detailCardBackground
        donutChartView.data = [
            DonutChartView.SliceData(value: Double(current.count), colors: [.primaryGradientStart, .primaryGradientEnd], label: "\(current.count)회"),
            DonutChartView.SliceData(value: Double(previous.count), colors: [.blueGradientStart, .blueGradientEnd], label: "\(previous.count)회")
        ]
        addSubview(donutChartView)
    }

    private func setupConstraints() {
        descriptionLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        rankLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        donutChartView.snp.makeConstraints {
            $0.top.equalTo(rankLabel.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(220)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
