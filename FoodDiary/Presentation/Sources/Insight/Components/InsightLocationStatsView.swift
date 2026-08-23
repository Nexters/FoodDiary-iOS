//
//  InsightLocationStatsView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

final class InsightLocationStatsView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let bubbleChartHeight: CGFloat = 250
    }

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let bubbleChartView = BubbleChartView()

    // MARK: - Init

    init(locationStats: [LocationStat]) {
        super.init(frame: .zero)
        setupUI(locationStats: locationStats)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(locationStats: [LocationStat]) {
        backgroundColor = .detailCardBackground
        layer.cornerRadius = 16
        clipsToBounds = true

        let sorted = locationStats.sorted { $0.count > $1.count }
        guard let topLocation = sorted.first else { return }

        let attributed = NSMutableAttributedString()
        attributed.append(Typography.hd15.styled("이번 달 가장 많이 간 지역은\n", color: .gray850, lineSpacing: 6))
        attributed.append(Typography.hd15.styled("\(topLocation.count)회 ", color: .gray850))
        attributed.append(Typography.hd15.styled(topLocation.dong, color: .primary))
        titleLabel.attributedText = attributed
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        // 옅은 알파값의 버블은 밝은 카드 배경과 섞이므로, 흰색 라벨 대신 어두운 라벨을 사용해 대비를 유지한다.
        let colors: [UIColor] = [
            .primary,
            .primary.withAlphaComponent(0.5),
            .primary.withAlphaComponent(0.25)
        ]
        let textColors: [UIColor] = [.white, .gray850, .gray850]

        bubbleChartView.data = sorted.prefix(3).enumerated().map { index, stat in
            BubbleChartView.BubbleData(
                label: stat.dong,
                count: stat.count,
                color: colors[index],
                textColor: textColors[index]
            )
        }
        addSubview(bubbleChartView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        bubbleChartView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(Constants.bubbleChartHeight)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
