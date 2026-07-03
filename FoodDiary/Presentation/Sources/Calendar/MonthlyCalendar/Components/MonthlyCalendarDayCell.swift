//
//  MonthlyCalendarDayCell.swift
//  Presentation
//

import DesignSystem
import Domain
import Kingfisher
import SnapKit
import UIKit

/// 월간 캘린더의 날짜 셀
final class MonthlyCalendarDayCell: UICollectionViewCell {

    private enum Constants {
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 1.5
    }

    static let reuseIdentifier = "MonthlyCalendarDayCell"

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .calendarTileBackground
        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()

    private let dayNumberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowRadius = 3
        return label
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
        resetCellState()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(dayNumberLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        dayNumberLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with day: MonthlyCalendarDay, selectedDate: Date) {
        applyRecordStyle(photoURLs: day.imageURLs)

        applyDayNumberStyle(
            dayNumber: day.dayNumber,
            isCurrentMonth: day.isCurrentMonth
        )

        applySelectionStyle(isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate))
    }

    private func resetCellState() {
        isUserInteractionEnabled = true
        containerView.backgroundColor = .calendarTileBackground
        containerView.removeGradient()
        containerView.removeGlow()
        containerView.layer.borderColor = UIColor.clear.cgColor
        containerView.layer.borderWidth = 0
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.isHidden = true
        dayNumberLabel.layer.shadowOpacity = 0
    }

    private func applyRecordStyle(photoURLs: [URL]) {
        guard let imageURL = photoURLs.first else { return }
        imageView.isHidden = false
        imageView.kf.setImage(with: imageURL)
    }

    private func applyDayNumberStyle(
        dayNumber: Int,
        isCurrentMonth: Bool
    ) {
        let formattedDayNumber = String(format: "%d", dayNumber)
        let hasImage = !imageView.isHidden
        let color: UIColor = hasImage ? .white : (isCurrentMonth ? .gray300 : .gray100)
        dayNumberLabel.layer.shadowOpacity = hasImage ? 1 : 0
        dayNumberLabel.setText(formattedDayNumber, style: .p12, color: color, alignment: .center)
    }

    private func applySelectionStyle(isSelected: Bool) {
        containerView.layer.borderWidth = isSelected ? Constants.borderWidth : 0
        containerView.layer.borderColor = isSelected ? UIColor.primary.cgColor : UIColor.clear.cgColor
    }
}
