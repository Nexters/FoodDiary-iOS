//
//  InsightDiaryTimeStatsView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

final class InsightDiaryTimeStatsView: UIView {

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let bigTimeLabel = UILabel()

    // MARK: - Init

    init(diaryTimeStats: DiaryTimeStats) {
        super.init(frame: .zero)
        setupUI(diaryTimeStats: diaryTimeStats)
        setupConstraints()
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

        let hour = diaryTimeStats.mostActiveHour
        let timeText = String(format: "%d:00", hour)

        titleLabel.setText("식사는 늘,", style: .hd18, color: .primary)
        addSubview(titleLabel)

        let timeAttr = Typography.hd20.styled(timeText, color: .primary)
        let suffixAttr = Typography.hd20.styled(" 이 제일 많았어요", color: .gray200)
        let combined = NSMutableAttributedString()
        combined.append(timeAttr)
        combined.append(suffixAttr)
        subtitleLabel.attributedText = combined
        addSubview(subtitleLabel)

        descriptionLabel.setText(
            "이 시간대에 음식 사진이 가장 많이 남았어요.",
            style: .p14,
            color: .gray400
        )
        descriptionLabel.numberOfLines = 0
        addSubview(descriptionLabel)

        bigTimeLabel.attributedText = NSAttributedString(
            string: timeText,
            attributes: [
                .font: DesignSystemFontFamily.Pretendard.bold.font(size: 50),
                .foregroundColor: UIColor.primary
            ]
        )
        bigTimeLabel.textAlignment = .center
        addSubview(bigTimeLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        bigTimeLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(28)
        }
    }
}
