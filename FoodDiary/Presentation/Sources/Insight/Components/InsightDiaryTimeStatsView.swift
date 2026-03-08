//
//  InsightDiaryTimeStatsView.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

final class InsightDiaryTimeStatsView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let barMaxHeight: CGFloat = 80
        static let barWidth: CGFloat = 6
        static let barSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let activeHourLabel = UILabel()
    private let chartContainerView = UIView()

    // MARK: - Init

    init(diaryTimeStats: DiaryTimeStats) {
        super.init(frame: .zero)
        setupUI(diaryTimeStats: diaryTimeStats)
        setupConstraints()
        buildChart(distribution: diaryTimeStats.distribution)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(diaryTimeStats: DiaryTimeStats) {
        backgroundColor = .sd900
        layer.cornerRadius = 16
        clipsToBounds = true

        titleLabel.setText("⏰ 기록 시간대", style: .hd18)
        addSubview(titleLabel)

        let hour = diaryTimeStats.mostActiveHour
        let hourText = String(format: "%02d시", hour)
        activeHourLabel.setText("주로 \(hourText)에 기록해요", style: .p15, color: .gray050)
        addSubview(activeHourLabel)

        addSubview(chartContainerView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        activeHourLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        chartContainerView.snp.makeConstraints {
            $0.top.equalTo(activeHourLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(Constants.barMaxHeight + 20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    private func buildChart(distribution: [HourCount]) {
        let maxCount = distribution.map(\.count).max() ?? 1

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.distribution = .equalSpacing
        stackView.spacing = Constants.barSpacing
        chartContainerView.addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        for hourCount in distribution {
            let ratio = maxCount > 0
                ? CGFloat(hourCount.count) / CGFloat(maxCount)
                : 0
            let barHeight = max(2, Constants.barMaxHeight * ratio)

            let barView = UIView()
            barView.backgroundColor = hourCount.count == maxCount ? .primary : .sd700
            barView.layer.cornerRadius = Constants.barWidth / 2

            barView.snp.makeConstraints {
                $0.width.equalTo(Constants.barWidth)
                $0.height.equalTo(barHeight)
            }

            stackView.addArrangedSubview(barView)
        }
    }
}
