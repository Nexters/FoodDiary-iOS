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

    // MARK: - Constants

    private enum Constants {
        static let containerCornerRadius: CGFloat = 24
        static let containerBorderWidth: CGFloat = 1
        static let containerHorizontalInset: CGFloat = 0
        static let containerBackgroundAlpha: CGFloat = 0.05
        static let cardHorizontalInset: CGFloat = 30
        static let pendingCardHorizontalInset: CGFloat = 15
        static let cardAspectRatio: CGFloat = 1.0
    }

    // MARK: - Publishers

    var addButtonTapPublisher: AnyPublisher<Void, Never> {
        addButtonTapSubject.eraseToAnyPublisher()
    }

    var cardStackTapPublisher: AnyPublisher<FoodRecord, Never> {
        cardStackTapSubject.eraseToAnyPublisher()
    }

    var processingTapPublisher: AnyPublisher<Date, Never> {
        processingTapSubject.eraseToAnyPublisher()
    }

    private let addButtonTapSubject = PassthroughSubject<Void, Never>()
    private let cardStackTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let processingTapSubject = PassthroughSubject<Date, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .sd900
        view.layer.cornerRadius = Constants.containerCornerRadius
        view.layer.borderWidth = Constants.containerBorderWidth
        view.layer.borderColor = UIColor.sd800.cgColor
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

    // Processing State UI
    private let processingStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.clipsToBounds = false
        return view
    }()

    private var processingCardView: PendingFoodRecordCardView?
    private var currentProcessingDate: Date?
    private var currentState: State?

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

        // Processing State
        containerView.addSubview(processingStateView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0, left: Constants.containerHorizontalInset, bottom: 0,
                    right: Constants.containerHorizontalInset))
        }

        // Card Stack State Constraints
        cardStackStateView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // Processing State Constraints
        processingStateView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(state: State) {
        guard currentState != state else { return }
        currentState = state

        switch state {
        case .empty:
            showEmptyState()
        case .processing(let records):
            if let first = records.first {
                showProcessingState(record: first)
            }
        case .recorded(let records):
            if let first = records.first {
                showCardStackState(record: first, totalCount: records.count)
            }
        }
    }

    private func showProcessingState(record: FoodRecord) {
        emptyStateView?.removeFromSuperview()
        emptyStateView = nil
        cardStackStateView.isHidden = true
        processingStateView.isHidden = false
        showContainerStyle(false)
        cancellables.removeAll()
        currentProcessingDate = record.date

        // 기존 processing 카드 제거
        processingCardView?.removeFromSuperview()

        // 새로 생성
        let imageURL = record.photos.first?.imageURL
        let newProcessingCardView = PendingFoodRecordCardView(imageURL: imageURL)
        processingStateView.addSubview(newProcessingCardView)
        processingCardView = newProcessingCardView

        newProcessingCardView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(Constants.pendingCardHorizontalInset)
            $0.height.equalTo(newProcessingCardView.snp.width)
        }

        // 탭 제스처
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(processingCardTapped))
        newProcessingCardView.addGestureRecognizer(tapGesture)
    }

    @objc private func processingCardTapped() {
        guard let date = currentProcessingDate else { return }
        processingTapSubject.send(date)
    }

    private func showContainerStyle(_ show: Bool) {
        containerView.backgroundColor = show ? .sd900 : .clear
        containerView.layer.borderWidth = show ? Constants.containerBorderWidth : 0
    }

    private func showEmptyState() {
        cardStackStateView.isHidden = true
        processingStateView.isHidden = true
        showContainerStyle(false)

        // 기존 empty 뷰 제거
        emptyStateView?.removeFromSuperview()
        cancellables.removeAll()

        // 새로 생성
        let newEmptyView = EmptyFoodRecordView(text: "오늘의 음식 사진을 추가해보세요")
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
        processingStateView.isHidden = true
        processingCardView?.removeFromSuperview()
        showContainerStyle(false)

        // 기존 카드스택뷰 제거
        cardStackView?.removeFromSuperview()
        cancellables.removeAll()

        // 새로 생성
        let newCardStackView = FoodRecordCardStackView(record: record, totalCount: totalCount)
        cardStackStateView.addSubview(newCardStackView)
        cardStackView = newCardStackView

        newCardStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(Constants.cardHorizontalInset)
            $0.height.equalTo(newCardStackView.snp.width).multipliedBy(Constants.cardAspectRatio)
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
        case empty
        case processing([FoodRecord])
        case recorded([FoodRecord])
    }
}
