//
//  InsightHeaderView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

final class InsightHeaderView: UIView {

    // MARK: - UI Components

    private let dateLabel = UILabel()
    private let titleLabel = UILabel()

    // MARK: - Init

    init(date: Date = Date()) {
        super.init(frame: .zero)
        setupUI(date: date)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        dateLabel.setText(formatter.string(from: date), style: .p12, color: .gray050)

        let attributed = NSMutableAttributedString()
        attributed.append(Typography.hd20.styled("이번 달, ", color: .primary))
        attributed.append(Typography.hd20.styled("잘 먹었습니다.", color: .gray050))
        titleLabel.attributedText = attributed
        titleLabel.numberOfLines = 0

        addSubview(dateLabel)
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        dateLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}
