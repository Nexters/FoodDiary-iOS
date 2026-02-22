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

    private enum Constants {
        static let cornerRadius: CGFloat = 8
        static let stackHorizontalInset: CGFloat = 4
        static let stackVerticalInset: CGFloat = 6
        static let todayBorderWidth: CGFloat = 1
    }

    static let reuseIdentifier = "MonthlyCalendarDayCell"

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [dayNumberLabel, dashedBorderView, polaroidImageCardsView])
        view.backgroundColor = .clear
        view.axis = .vertical
        view.alignment = .center
        view.spacing = 6
        view.clipsToBounds = true
        view.layer.cornerRadius = Constants.cornerRadius
        return view
    }()

    private let dayNumberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let dashedBorderView = DashedBorderView()

    private let polaroidImageCardsView: PolaroidImageCardsView = {
        let view = PolaroidImageCardsView()
        view.isHidden = true
        return view
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

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.updateGradientFrame()
    }

    // MARK: - Setup

    private func setupUI() {
        dashedBorderView.clipsToBounds = true
        dashedBorderView.layer.cornerRadius = Constants.cornerRadius

        contentView.addSubview(containerView)
        containerView.addSubview(stackView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Constants.stackHorizontalInset)
            $0.top.bottom.equalToSuperview().inset(Constants.stackVerticalInset)
            $0.center.equalToSuperview()
        }

        dashedBorderView.snp.makeConstraints {
            $0.height.equalTo(dashedBorderView.snp.width)
        }

        polaroidImageCardsView.snp.makeConstraints {
            $0.height.equalTo(polaroidImageCardsView.snp.width)
        }
    }

    // MARK: - Configuration

    func configure(with day: MonthlyCalendarDay) {
        isUserInteractionEnabled = day.isCurrentMonth

        applyRecordStyle(photoURLs: day.imageURLs, isCurrentMonth: day.isCurrentMonth)

        applyDayNumberStyle(
            dayNumber: day.dayNumber,
            isCurrentMonth: day.isCurrentMonth,
            isToday: day.isToday,
        )

        if day.isToday {
            applyTodayStyle()
        }
    }
    
    private func resetCellState() {
        isUserInteractionEnabled = true
        dashedBorderView.backgroundColor = .clear
        containerView.backgroundColor = .clear
        containerView.removeGradient()
        containerView.removeGlow()
        containerView.layer.borderColor = UIColor.clear.cgColor
        stackView.backgroundColor = .clear
        dashedBorderView.isHidden = false
        polaroidImageCardsView.isHidden = true
        polaroidImageCardsView.alpha = 1
    }

    private func applyTodayStyle() {
        containerView.backgroundColor = .primary
        containerView.layer.borderWidth = Constants.todayBorderWidth
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        containerView.applyGlow(
            glowColor: .primary,
            borderColor: UIColor.white.withAlphaComponent(0.3),
            cornerRadius: Constants.cornerRadius
        )
        dashedBorderView.backgroundColor = .white.withAlphaComponent(0.2)
        dashedBorderView.layer.borderColor = DesignSystemAsset.sd800.color.cgColor
    }

    private func applyRecordStyle(photoURLs: [URL], isCurrentMonth: Bool) {
        let hasPhoto = !photoURLs.isEmpty
        dashedBorderView.isHidden = hasPhoto
        polaroidImageCardsView.isHidden = !hasPhoto

        guard hasPhoto else { return }

        polaroidImageCardsView.alpha = isCurrentMonth ? 1 : 0.3

        if photoURLs.count == 1 {
            polaroidImageCardsView.configure(imageURL: photoURLs[0])
        } else {
            polaroidImageCardsView.configure(backImageURL: photoURLs[0], frontImageURL: photoURLs[1])
        }
    }

    private func applyDayNumberStyle(
        dayNumber: Int,
        isCurrentMonth: Bool,
        isToday: Bool,
        isSelected: Bool
    ) {
        let formattedDayNumber = String(format: "%02d", dayNumber)
        if isCurrentMonth {
            dayNumberLabel.setText(formattedDayNumber, style: .p12, color: .white)
        } else {
            dayNumberLabel.setText(formattedDayNumber, style: .p12, color: DesignSystemAsset.gray700.color)
        }
    }
}
