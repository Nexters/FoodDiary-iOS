//
//  FoodRecordCardStackView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

/// 음식 기록 카드 스택 뷰 (카드가 겹쳐 보이는 효과)
public final class FoodRecordCardStackView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let maxVisibleCards = 3
        static let cardOffset: CGFloat = 8
        static let rotationAngle: CGFloat = 3.0 // degrees
    }

    // MARK: - Publishers

    private let copyTapSubject = PassthroughSubject<String, Never>()
    public var copyTapPublisher: AnyPublisher<String, Never> {
        copyTapSubject.eraseToAnyPublisher()
    }

    private let cardTapSubject = PassthroughSubject<FoodRecord, Never>()
    public var cardTapPublisher: AnyPublisher<FoodRecord, Never> {
        cardTapSubject.eraseToAnyPublisher()
    }

    // MARK: - State

    private var frontCardView: FoodRecordCardView?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private let stackContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        return view
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
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
        clipsToBounds = false
        addSubview(stackContainer)
    }

    private func setupConstraints() {
        stackContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    public func configure(with record: FoodRecord, totalCount: Int) {
        clearCards()

        let visibleCount = min(totalCount, Constants.maxVisibleCards)

        // 뒤쪽 빈 카드들 먼저 추가 (z-order)
        addBackgroundCards(count: visibleCount - 1, totalCount: visibleCount)

        // 맨 앞 실제 카드 추가
        addFrontCard(record: record)
    }

    // MARK: - Private Methods

    private func clearCards() {
        stackContainer.subviews.forEach { $0.removeFromSuperview() }
        frontCardView = nil
        cancellables.removeAll()
    }

    private func addBackgroundCards(count: Int, totalCount: Int) {
        for i in 0..<count {
            let reverseIndex = count - i // 뒤에서부터 1, 2, ...

            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 20
            card.isUserInteractionEnabled = false

            stackContainer.addSubview(card)

            card.snp.makeConstraints {
                $0.top.equalToSuperview().offset(CGFloat(reverseIndex) * Constants.cardOffset)
                $0.centerX.equalToSuperview()
                $0.width.equalToSuperview().offset(-CGFloat(reverseIndex) * Constants.cardOffset * 2)
                $0.bottom.equalToSuperview().offset(-CGFloat(totalCount - 1 - reverseIndex) * Constants.cardOffset)
            }

            // 회전 효과
            let rotation = CGFloat(reverseIndex) * Constants.rotationAngle * .pi / 180
            let direction: CGFloat = reverseIndex % 2 == 0 ? 1 : -1
            card.transform = CGAffineTransform(rotationAngle: rotation * direction)
        }
    }

    private func addFrontCard(record: FoodRecord) {
        let cardView = FoodRecordCardView(record: record)

        cardView.copyTapPublisher
            .sink { [weak self] address in
                self?.copyTapSubject.send(address)
            }
            .store(in: &cancellables)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(frontCardTapped))
        cardView.addGestureRecognizer(tapGesture)

        stackContainer.addSubview(cardView)
        frontCardView = cardView

        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    @objc private func frontCardTapped() {
        guard let record = frontCardView?.record else { return }
        cardTapSubject.send(record)
    }
}
