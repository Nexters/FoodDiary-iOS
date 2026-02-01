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
        static let rotationAngle: CGFloat = 5.0
        static let maxBackgroundAlpha: CGFloat = 0.75
        static let minBackgroundAlpha: CGFloat = 0.50
        static let baseShadowOpacity: Float = 0.2
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
    private var backgroundCards: [(card: UIView, reverseIndex: Int)] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private let stackContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        return view
    }()

    // MARK: - Properties

    private let record: FoodRecord
    private let totalCount: Int

    // MARK: - Init

    public init(record: FoodRecord, totalCount: Int) {
        self.record = record
        self.totalCount = totalCount
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutBackgroundCards()
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

    private func configure() {
        let visibleCount = min(totalCount, Constants.maxVisibleCards)

        // 뒤쪽 빈 카드들 먼저 추가 (z-order)
        addBackgroundCards(count: visibleCount - 1)

        // 맨 앞 실제 카드 추가
        addFrontCard(record: record)
    }

    private func addBackgroundCards(count: Int) {
        for i in 0..<count {
            let reverseIndex = count - i // 뒤에서부터 1, 2, ...

            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 20
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = Constants.baseShadowOpacity
            card.layer.shadowOffset = CGSize(width: 0, height: 4)
            card.layer.shadowRadius = 8
            card.layer.masksToBounds = false
            card.isUserInteractionEnabled = false

            stackContainer.addSubview(card)
            backgroundCards.append((card: card, reverseIndex: reverseIndex))
        }
    }

    private func layoutBackgroundCards() {
        let containerBounds = stackContainer.bounds
        guard !containerBounds.isEmpty else { return }

        for (card, reverseIndex) in backgroundCards {
            let offset = CGFloat(reverseIndex) * Constants.cardOffset
            let rotation = CGFloat(reverseIndex) * Constants.rotationAngle * .pi / 180
            let direction: CGFloat = reverseIndex % 2 == 0 ? 1 : -1

            card.transform = .identity
            card.frame = containerBounds
            card.center = CGPoint(
                x: containerBounds.midX,
                y: containerBounds.midY + offset
            )

            // Shadow path + depth alpha
            card.layer.shadowPath = UIBezierPath(
                roundedRect: card.bounds,
                cornerRadius: card.layer.cornerRadius
            ).cgPath
            card.alpha = backgroundAlpha(for: reverseIndex)

            // 회전 효과가 보이도록 살짝 아래로 빼고 회전 적용
            card.transform = CGAffineTransform(rotationAngle: rotation * direction)
        }
    }

    private func backgroundAlpha(for reverseIndex: Int) -> CGFloat {
        let maxAlpha = Constants.maxBackgroundAlpha
        let minAlpha = Constants.minBackgroundAlpha
        let stepCount = max(1, Constants.maxVisibleCards - 1)
        let step = (maxAlpha - minAlpha) / CGFloat(stepCount)
        let alpha = maxAlpha - (CGFloat(reverseIndex) - 1) * step
        return max(minAlpha, min(maxAlpha, alpha))
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
