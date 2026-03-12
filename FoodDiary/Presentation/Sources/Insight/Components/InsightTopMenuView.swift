//
//  InsightTopMenuView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

final class InsightTopMenuView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let maxBarHeight: CGFloat = 160
        static let lineCount: Int = 6
        static let barSpacing: CGFloat = 8
        static let weekLabelHeight: CGFloat = 20
    }

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let separatorView = UIView()
    private let chartContainerView = UIView()
    private let linesStackView = UIStackView()
    private let barsStackView = UIStackView()

    // MARK: - Init

    init(weeklyStats: WeeklyStats) {
        super.init(frame: .zero)
        setupUI(weeklyStats: weeklyStats)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(weeklyStats: WeeklyStats) {
        backgroundColor = .sd900
        layer.cornerRadius = 16
        clipsToBounds = true

        setupTitle(week: weeklyStats.mostActiveWeek)
        setupSeparator()
        setupChart(weeklyStats: weeklyStats)
    }

    private func setupTitle(week: Int) {
        let attributed = NSMutableAttributedString()
        attributed.append(Typography.hd15.styled("가장 활발하게\n기록한 주는 ", color: .white, lineSpacing: 6))
        attributed.append(Typography.hd15.styled("\(week)주차", color: .primary))

        titleLabel.attributedText = attributed
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
    }

    private func setupSeparator() {
        separatorView.backgroundColor = .sd800
        addSubview(separatorView)
    }

    private func setupChart(weeklyStats: WeeklyStats) {
        addSubview(chartContainerView)

        // Grid lines
        linesStackView.axis = .vertical
        linesStackView.distribution = .equalSpacing
        chartContainerView.addSubview(linesStackView)

        for _ in 0..<Constants.lineCount {
            let line = UIView()
            line.backgroundColor = .sd800
            line.translatesAutoresizingMaskIntoConstraints = false
            line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            linesStackView.addArrangedSubview(line)
        }

        // Bars stack
        barsStackView.axis = .horizontal
        barsStackView.distribution = .fillEqually
        barsStackView.spacing = Constants.barSpacing
        barsStackView.alignment = .bottom
        chartContainerView.addSubview(barsStackView)

        guard !weeklyStats.weeklyCounts.isEmpty else { return }

        let maxCount = weeklyStats.weeklyCounts.map(\.count).max() ?? 1

        for weekCount in weeklyStats.weeklyCounts {
            let column = makeBarColumn(weekCount: weekCount, maxCount: maxCount)
            barsStackView.addArrangedSubview(column)
        }
    }

    private func makeBarColumn(weekCount: WeekCount, maxCount: Int) -> UIView {
        let column = UIView()

        let barView = GradientBarView(colors: [.primaryGradientStart, .primaryGradientEnd])
        column.addSubview(barView)

        let countLabel = UILabel()
        countLabel.setText("\(weekCount.count)회", style: .p12, color: .white)
        countLabel.textAlignment = .center
        barView.addSubview(countLabel)

        let weekLabel = UILabel()
        weekLabel.setText("\(weekCount.week)주차", style: .p10, color: .gray200)
        weekLabel.textAlignment = .center
        column.addSubview(weekLabel)

        let ratio = weekCount.count > 0
            ? CGFloat(weekCount.count) / CGFloat(maxCount)
            : 0
        let barHeight = max(Constants.maxBarHeight * ratio, weekCount.count > 0 ? 24 : 0)

        barView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(weekLabel.snp.top).offset(-8)
            $0.height.equalTo(barHeight)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(6)
            $0.centerX.equalToSuperview()
        }

        weekLabel.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(Constants.weekLabelHeight)
        }

        return column
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        separatorView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(0.5)
        }

        chartContainerView.snp.makeConstraints {
            $0.top.equalTo(separatorView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(Constants.maxBarHeight + Constants.weekLabelHeight + 8)
            $0.bottom.equalToSuperview().inset(20)
        }

        linesStackView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(Constants.maxBarHeight)
        }

        barsStackView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalToSuperview()
        }
    }
}
