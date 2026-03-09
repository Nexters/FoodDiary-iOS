//
//  InsightPhotoStatsView.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

final class InsightPhotoStatsView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let maxBarHeight: CGFloat = 160
        static let lineCount: Int = 6
    }

    // MARK: - UI Components

    private let descriptionLabel = UILabel()
    private let changeRateStackView = UIStackView()
    private let headerStackView = UIStackView()
    private let chartContainerView = UIView()
    private let linesStackView = UIStackView()
    private let barsStackView = UIStackView()
    private let monthLabelsStackView = UIStackView()

    private struct BarInfo {
        let barView: GradientBarView
        let label: UIView
        let barHeight: CGFloat
    }
    private var barInfos: [BarInfo] = []

    // MARK: - Init

    init(photoStats: PhotoStats, month: String) {
        super.init(frame: .zero)
        setupUI(photoStats: photoStats, month: month)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(photoStats: PhotoStats, month: String) {
        backgroundColor = .sd900
        layer.cornerRadius = 16
        clipsToBounds = true

        descriptionLabel.setText("먹기 전에\n카메라부터 찾았네요.", style: .hd16, color: .gray050)
        descriptionLabel.numberOfLines = 2

        setupChangeRateLabel(photoStats: photoStats)

        headerStackView.axis = .vertical
        headerStackView.spacing = 10
        headerStackView.addArrangedSubview(descriptionLabel)
        headerStackView.addArrangedSubview(changeRateStackView)
        addSubview(headerStackView)

        setupChart(photoStats: photoStats, month: month)
    }

    private func setupChangeRateLabel(photoStats: PhotoStats) {
        let rate = photoStats.changeRate
        let rateColor: UIColor = rate >= 0 ? .primary : .rn500

        let prefixLabel = UILabel()
        prefixLabel.setText("지난 달 대비 기록된 사진이 ", style: .p10, color: .gray050)

        let valueLabel = UILabel()
        valueLabel.setText("\(Int(rate))%", style: .hd16, color: rateColor)

        let suffixLabel = UILabel()
        suffixLabel.setText(" 증가했어요.", style: .p10, color: .gray050)

        changeRateStackView.axis = .horizontal
        changeRateStackView.alignment = .center
        changeRateStackView.spacing = 0
        changeRateStackView.addArrangedSubview(prefixLabel)
        changeRateStackView.addArrangedSubview(valueLabel)
        changeRateStackView.addArrangedSubview(suffixLabel)
    }

    private func setupChart(photoStats: PhotoStats, month: String) {
        addSubview(chartContainerView)

        setupLines()
        setupBars(photoStats: photoStats, month: month)
        setupMonthLabels(photoStats: photoStats, month: month)
    }

    private func setupLines() {
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
    }

    private func setupBars(photoStats: PhotoStats, month: String) {
        barsStackView.axis = .horizontal
        barsStackView.distribution = .fill
        barsStackView.alignment = .bottom
        barsStackView.spacing = 60
        chartContainerView.addSubview(barsStackView)

        let prevCount = CGFloat(photoStats.previousMonthCount)
        let currCount = CGFloat(photoStats.currentMonthCount)
        let total = prevCount + currCount

        let counts = [prevCount, currCount]
        let countInts = [Int(prevCount), Int(currCount)]
        let gradientColors: [[UIColor]] = [
            [.blueGradientStart, .blueGradientEnd],
            [.primaryGradientStart, .primaryGradientEnd]
        ]

        for (i, count) in counts.enumerated() {
            let barHeight = total > 0 ? (count / total) * Constants.maxBarHeight : 0
            let barView = GradientBarView(colors: gradientColors[i])

            let label = UILabel()
            label.text = "\(countInts[i])"
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .white
            label.textAlignment = .center

            barView.addSubview(label)

            barInfos.append(BarInfo(barView: barView, label: label, barHeight: barHeight))
            barsStackView.addArrangedSubview(barView)
        }
    }

    private func setupMonthLabels(photoStats: PhotoStats, month: String) {
        monthLabelsStackView.axis = .horizontal
        monthLabelsStackView.distribution = .fill
        monthLabelsStackView.spacing = 60
        addSubview(monthLabelsStackView)

        let currentMonthNum = month.split(separator: "-").last.flatMap { Int($0) } ?? 1
        let previousMonthNum = currentMonthNum == 1 ? 12 : currentMonthNum - 1

        for name in ["\(previousMonthNum)월", "\(currentMonthNum)월"] {
            let label = UILabel()
            label.setText(name, style: .p10, color: .gray200)
            label.textAlignment = .center
            label.snp.makeConstraints { $0.width.equalTo(60) }
            monthLabelsStackView.addArrangedSubview(label)
        }
    }

    private func setupConstraints() {
        headerStackView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        chartContainerView.snp.makeConstraints {
            $0.top.equalTo(headerStackView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(Constants.maxBarHeight)
        }

        linesStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        barsStackView.snp.makeConstraints {
            $0.centerX.bottom.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
        }

        for info in barInfos {
            info.barView.snp.makeConstraints {
                $0.width.equalTo(60)
                $0.height.equalTo(info.barHeight)
            }

            info.label.snp.makeConstraints {
                $0.top.equalToSuperview().inset(6)
                $0.centerX.equalToSuperview()
            }
        }

        monthLabelsStackView.snp.makeConstraints {
            $0.top.equalTo(chartContainerView.snp.bottom).offset(8)
            $0.centerX.equalTo(barsStackView)
            $0.width.equalTo(barsStackView)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}

// MARK: - GradientBarView

private final class GradientBarView: UIView {

    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        clipsToBounds = true
        layer.cornerRadius = 4
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
