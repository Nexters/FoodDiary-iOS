//
//  DetailFoodCardCell.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

/// 상세 화면용 음식 기록 카드 셀
final class DetailFoodCardCell: UICollectionViewCell {

    static let reuseIdentifier = "DetailFoodCardCell"

    // MARK: - UI Components

    private var cardView: FoodRecordCardView?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(with record: FoodRecord, imageURL: URL) {
        cardView?.removeFromSuperview()

        let newCardView = FoodRecordCardView(record: record, imageURL: imageURL)
        contentView.addSubview(newCardView)
        newCardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        cardView = newCardView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView?.removeFromSuperview()
        cardView = nil
    }
}
