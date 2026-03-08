//
//  InsightPhotoStatsView.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

final class InsightPhotoStatsView: UIView {

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let changeRateLabel = UILabel()

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

        titleLabel.setText("📸 사진 기록", style: .hd18)
        addSubview(titleLabel)

        let countText = "\(month)에 \(photoStats.currentMonthCount)장의 사진을 기록했어요"
        countLabel.setText(countText, style: .p15, color: .gray050)
        countLabel.numberOfLines = 0
        addSubview(countLabel)

        let rate = photoStats.changeRate
        let sign = rate >= 0 ? "+" : ""
        let rateText = "지난 달(\(photoStats.previousMonthCount)장) 대비 \(sign)\(Int(rate))%"
        let rateColor: UIColor = rate >= 0 ? .primary : .gray300
        changeRateLabel.setText(rateText, style: .p14, color: rateColor)
        addSubview(changeRateLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        changeRateLabel.snp.makeConstraints {
            $0.top.equalTo(countLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
