//
//  MealSectionView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

/// 식사 타입별 섹션 뷰 (아침, 점심, 저녁)
final class MealSectionView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let titleTopInset: CGFloat = 42
        static let contentTopInset: CGFloat = 16
        static let horizontalInset: CGFloat = 20
        static let textHorizontalInset: CGFloat = Self.horizontalInset + 10
        static let pendingCardHorizontalInset: CGFloat = 40
    }

    // MARK: - Publishers

    var copyTapPublisher: AnyPublisher<FoodRecord, Never> {
        copyTapSubject.eraseToAnyPublisher()
    }

    var shareTapPublisher: AnyPublisher<FoodRecord, Never> {
        shareTapSubject.eraseToAnyPublisher()
    }

    var editTapPublisher: AnyPublisher<FoodRecord, Never> {
        editTapSubject.eraseToAnyPublisher()
    }

    var addButtonTapPublisher: AnyPublisher<Void, Never> {
        addButtonTapSubject.eraseToAnyPublisher()
    }

    private let copyTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let shareTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let editTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let addButtonTapSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State

    private let mealType: MealType
    private var currentState: State?
    private var currentDisplayedRecord: FoodRecord?

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()

    private let editButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        return button
    }()

    private let contentContainerView = UIView()

    // MARK: - Init

    init(mealType: MealType) {
        self.mealType = mealType
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        configureTitleLabel()
        configureEditButton()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(editButton)
        addSubview(contentContainerView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.titleTopInset)
            $0.leading.equalToSuperview().offset(Constants.textHorizontalInset)
        }

        editButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-Constants.textHorizontalInset)
        }

        contentContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Constants.contentTopInset)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    private func setupActions() {
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
    }

    private func configureTitleLabel() {
        let title: String
        switch mealType {
        case .breakfast:
            title = "아침"
        case .lunch:
            title = "점심"
        case .dinner:
            title = "저녁"
        case .lateNight:
            title = "야식"
        }
        titleLabel.setText(title, style: .hd20, color: .white)
    }

    private func configureEditButton() {
        let attributed = NSMutableAttributedString(attributedString: Typography.p14.styled("수정", color: .white))
        attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributed.length))
        editButton.setAttributedTitle(attributed, for: .normal)
    }

    // MARK: - Public Methods

    func configure(state: State) {
        guard currentState != state else { return }
        currentState = state

        cancellables.removeAll()
        contentContainerView.subviews.forEach { $0.removeFromSuperview() }

        switch state {
        case .empty:
            showEmptyState()
        case .pending(let records):
            showPendingState(records: records)
        case .recorded(let records):
            showRecordedState(records: records)
        }
    }

    // MARK: - State Rendering

    private func showEmptyState() {
        editButton.isHidden = true

        let emptyView = EmptyFoodRecordView(text: "오늘의 음식 사진을 추가해보세요.")
        contentContainerView.addSubview(emptyView)
        emptyView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.height.equalTo(emptyView.snp.width)
        }

        emptyView.addButtonTapPublisher
            .sink { [weak self] in
                self?.addButtonTapSubject.send()
            }
            .store(in: &cancellables)
    }

    private func showPendingState(records: [PendingFoodRecord]) {
        editButton.isHidden = true

        guard let firstRecord = records.first else { return }
        let pendingView = PendingFoodRecordCardView(record: firstRecord)
        contentContainerView.addSubview(pendingView)
        pendingView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.height.equalTo(pendingView.snp.width)
        }
    }

    private func showRecordedState(records: [FoodRecord]) {
        editButton.isHidden = false

        let recordedView = MealRecordedContentView(
            records: records,
            onCopyTapped: { [weak self] record in
                self?.copyTapSubject.send(record)
            },
            onShareTapped: { [weak self] record in
                self?.shareTapSubject.send(record)
            },
            onCurrentRecordChanged: { [weak self] record in
                self?.currentDisplayedRecord = record
            }
        )
        
        contentContainerView.addSubview(recordedView)
        recordedView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func editTapped() {
        guard let record = currentDisplayedRecord else { return }
        editTapSubject.send(record)
    }
}

// MARK: - State

extension MealSectionView {
    enum State: Equatable {
        case empty
        case pending([PendingFoodRecord])
        case recorded([FoodRecord])
    }
}
