//
//  BottomContentView.swift
//  Presentation
//

import Combine
import Domain
import SnapKit
import UIKit

/// 하단 영역 (+버튼 또는 기록된 카드 스택)
final class BottomContentView: UIView {

    // MARK: - Publishers

    var addButtonTapPublisher: AnyPublisher<Void, Never> {
        addButtonTapSubject.eraseToAnyPublisher()
    }

    var cardStackTapPublisher: AnyPublisher<FoodRecord, Never> {
        cardStackTapSubject.eraseToAnyPublisher()
    }

    private let addButtonTapSubject = PassthroughSubject<Void, Never>()
    private let cardStackTapSubject = PassthroughSubject<FoodRecord, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return view
    }()

    // Empty State UI (when no records)
    private var emptyStateView: EmptyFoodRecordView?

    // Card Stack UI (when records exist)
    private let cardStackStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.clipsToBounds = false
        return view
    }()

    private var cardStackView: FoodRecordCardStackView?

    // Pending State UI
    private let pendingStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.clipsToBounds = false
        return view
    }()

    private var pendingCardView: PendingFoodRecordCardView?

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
        addSubview(containerView)

        // Card Stack State
        containerView.addSubview(cardStackStateView)

        // Pending State
        containerView.addSubview(pendingStateView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }

        // Card Stack State Constraints
        cardStackStateView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // Pending State Constraints
        pendingStateView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(state: State) {
        switch state {
        case .empty(let photoCount):
            showEmptyState(photoCount: photoCount)
        case .pending(let records):
            if let first = records.first {
                showPendingState(record: first)
            }
        case .recorded(let records):
            if let first = records.first {
                showCardStackState(record: first, totalCount: records.count)
            }
        }
    }

    private func showPendingState(record: PendingFoodRecord) {
        emptyStateView?.removeFromSuperview()
        emptyStateView = nil
        cardStackStateView.isHidden = true
        pendingStateView.isHidden = false

        // 기존 pending 카드 제거
        pendingCardView?.removeFromSuperview()

        // 새로 생성
        let newPendingCardView = PendingFoodRecordCardView(record: record)
        pendingStateView.addSubview(newPendingCardView)
        pendingCardView = newPendingCardView

        newPendingCardView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(60)
            $0.height.equalTo(newPendingCardView.snp.width).multipliedBy(1.15)
        }
    }

    private func showEmptyState(photoCount: Int) {
        cardStackStateView.isHidden = true
        pendingStateView.isHidden = true

        // 기존 empty 뷰 제거
        emptyStateView?.removeFromSuperview()
        cancellables.removeAll()

        // 새로 생성
        let newEmptyView = EmptyFoodRecordView(photoCount: photoCount)
        containerView.addSubview(newEmptyView)
        emptyStateView = newEmptyView

        newEmptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // Publisher 바인딩
        newEmptyView.addButtonTapPublisher
            .sink { [weak self] in
                self?.addButtonTapSubject.send()
            }
            .store(in: &cancellables)
    }

    private func showCardStackState(record: FoodRecord, totalCount: Int) {
        emptyStateView?.removeFromSuperview()
        emptyStateView = nil
        cardStackStateView.isHidden = false
        pendingStateView.isHidden = true
        pendingCardView?.removeFromSuperview()

        // 기존 카드스택뷰 제거
        cardStackView?.removeFromSuperview()
        cancellables.removeAll()

        // 새로 생성
        let newCardStackView = FoodRecordCardStackView(record: record, totalCount: totalCount)
        cardStackStateView.addSubview(newCardStackView)
        cardStackView = newCardStackView

        newCardStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(60)
            $0.height.equalTo(newCardStackView.snp.width).multipliedBy(1.15)
        }

        // Publisher 바인딩
        newCardStackView.cardTapPublisher
            .sink { [weak self] record in
                self?.cardStackTapSubject.send(record)
            }
            .store(in: &cancellables)
    }

}

// MARK: - State

extension BottomContentView {
    enum State: Equatable {
        case empty(photoCount: Int)
        case pending([PendingFoodRecord])
        case recorded([FoodRecord])
    }
}
