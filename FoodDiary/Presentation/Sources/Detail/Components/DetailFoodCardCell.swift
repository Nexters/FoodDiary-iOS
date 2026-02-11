//
//  DetailFoodCardCell.swift
//  Presentation
//

import Combine
import Domain
import SnapKit
import UIKit

/// 상세 화면용 음식 기록 카드 셀
final class DetailFoodCardCell: UICollectionViewCell {

    static let reuseIdentifier = "DetailFoodCardCell"

    // MARK: - Publishers

    var copyTapPublisher: AnyPublisher<Void, Never> {
        cardView?.copyTapPublisher.map { _ in () }.eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()
    }

    var shareTapPublisher: AnyPublisher<Void, Never> {
        cardView?.shareTapPublisher.map { _ in () }.eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()
    }

    // MARK: - UI Components

    private var cardView: DetailFoodCardView?

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

        let newCardView = DetailFoodCardView(record: record, imageURL: imageURL)
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
