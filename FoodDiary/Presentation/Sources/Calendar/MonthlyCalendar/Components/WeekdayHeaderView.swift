//
//  WeekdayHeaderView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 요일 헤더 뷰 (월 화 수 목 금 토 일)
final class WeekdayHeaderView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    }

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .center
        return sv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(stackView)

        Constants.weekdays.enumerated().forEach { index, day in
            let label = UILabel()
            label.setText(day, style: .p12, color: index == 0 ? .redPostBase : .gray500)
            label.textAlignment = .center
            stackView.addArrangedSubview(label)
        }
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
