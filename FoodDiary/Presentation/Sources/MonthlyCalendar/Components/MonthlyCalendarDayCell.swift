//
//  MonthlyCalendarDayCell.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 월간 캘린더의 날짜 셀
final class MonthlyCalendarDayCell: UICollectionViewCell {

    static let reuseIdentifier = "MonthlyCalendarDayCell"

    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [dayNumberLabel, dashedBorderView])
        view.backgroundColor = .clear
        view.axis = .vertical
        view.alignment = .center
        view.spacing = 6
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private let dayNumberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let dashedBorderView = DashedBorderView()

    private let foodImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.image = DesignSystemAsset.tempImage.image
        imageView.isHidden = true
        return imageView
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

    override func prepareForReuse() {
        super.prepareForReuse()
        dashedBorderView.backgroundColor = .clear
        containerView.backgroundColor = .clear
        stackView.backgroundColor = .clear
        dashedBorderView.isHidden = false
        foodImageView.isHidden = true
    }

    // MARK: - Setup

    private func setupUI() {
        dashedBorderView.clipsToBounds = true
        dashedBorderView.layer.cornerRadius = 8

        contentView.addSubview(containerView)
        containerView.addSubview(stackView)
        stackView.addArrangedSubview(foodImageView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.leading.trailing.top.bottom.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(4)
            $0.top.bottom.equalToSuperview().inset(6)
            $0.center.equalToSuperview()
        }

        dashedBorderView.snp.makeConstraints {
            $0.height.equalTo(dashedBorderView.snp.width)
        }

        foodImageView.snp.makeConstraints {
            $0.height.equalTo(foodImageView.snp.width)
        }
    }

    // MARK: - Configuration

    func configure(with day: MonthlyCalendarDay, isSelected: Bool) {
        let hasRecord = !day.records.isEmpty
        dashedBorderView.isHidden = hasRecord
        foodImageView.isHidden = !hasRecord

        applyDayNumberStyle(
            dayNumber: day.dayNumber,
            isCurrentMonth: day.isCurrentMonth,
            isToday: day.isToday,
            isSelected: isSelected
        )
        
        if day.isToday {
            containerView.backgroundColor = DesignSystemAsset.primary.color
            dashedBorderView.backgroundColor = .white.withAlphaComponent(0.2)
            dashedBorderView.layer.borderColor = DesignSystemAsset.sd800.color.cgColor
        }
    }

    private func applyDayNumberStyle(
        dayNumber: String,
        isCurrentMonth: Bool,
        isToday: Bool,
        isSelected: Bool
    ) {
        if isCurrentMonth {
            dayNumberLabel.setText(dayNumber, style: .p12, color: .white)
        } else {
            dayNumberLabel.setText(dayNumber, style: .p12, color: DesignSystemAsset.gray700.color)
        }
    }
}
