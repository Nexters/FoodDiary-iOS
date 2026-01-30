//
//  DayCellView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 주간 캘린더의 개별 날짜 셀
final class DayCellView: UIView {

    var tapHandler: ((Date) -> Void)?
    private var date: Date?

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()

    private let dayOfWeekLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let dayNumberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let recordIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystemAsset.primary.color
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(dayOfWeekLabel)
        containerView.addSubview(dayNumberLabel)
        containerView.addSubview(recordIndicator)

        containerView.snp.makeConstraints { $0.edges.equalToSuperview().inset(2) }

        recordIndicator.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(4)
        }

        dayOfWeekLabel.snp.makeConstraints {
            $0.top.equalTo(recordIndicator.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }

        dayNumberLabel.snp.makeConstraints {
            $0.top.equalTo(dayOfWeekLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-8)
            $0.centerX.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    // MARK: - Configuration

    func configure(with dayData: WeeklyCalendarDay, isSelected: Bool) {
        self.date = dayData.date
        recordIndicator.isHidden = !dayData.hasRecord

        applyStyle(
            dayOfWeek: dayData.dayOfWeek,
            dayNumber: dayData.dayNumber,
            isToday: dayData.isToday,
            isSelected: isSelected
        )
    }

    private func applyStyle(dayOfWeek: String, dayNumber: String, isToday: Bool, isSelected: Bool) {
        if isSelected {
            containerView.backgroundColor = DesignSystemAsset.primary.color
            containerView.layer.cornerRadius = 8
            dayOfWeekLabel.setText(dayOfWeek, style: .p12, color: .white)
            dayNumberLabel.setText(dayNumber, style: .p12, color: .white)
            recordIndicator.backgroundColor = .white
        } else if isToday {
            containerView.backgroundColor = DesignSystemAsset.primary.color.withAlphaComponent(0.2)
            containerView.layer.cornerRadius = 8
            dayOfWeekLabel.setText(dayOfWeek, style: .p12, color: .gray300)
            dayNumberLabel.setText(dayNumber, style: .p12, color: .white)
            recordIndicator.backgroundColor = DesignSystemAsset.primary.color
        } else {
            containerView.backgroundColor = .clear
            containerView.layer.cornerRadius = 8
            dayOfWeekLabel.setText(dayOfWeek, style: .p12, color: .gray300)
            dayNumberLabel.setText(dayNumber, style: .p12, color: .white)
            recordIndicator.backgroundColor = DesignSystemAsset.primary.color
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        guard let date = date else { return }
        tapHandler?(date)
    }
}
