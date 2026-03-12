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

        let timeText = diaryTimeStats.mostActiveTime

        let attributed = NSMutableAttributedString()
        attributed.append(Typography.hd15.styled("식사는 늘,\n", color: .white, lineSpacing: 6))
        attributed.append(Typography.hd15.styled(timeText, color: .primary))
        attributed.append(Typography.hd15.styled(" 이 제일 많았어요", color: .gray200))

        titleLabel.attributedText = attributed
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

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

        bigTimeLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(28)
        }
    }
}
