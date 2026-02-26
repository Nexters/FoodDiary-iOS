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
        static let pendingCardHorizontalInset: CGFloat = horizontalInset + 6
        static let emptyImageSize: CGFloat = 160
        static let emptyTextTopSpacing: CGFloat = 25
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

    var addButtonTapPublisher: AnyPublisher<MealType, Never> {
        addButtonTapSubject.eraseToAnyPublisher()
    }

    private let copyTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let shareTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let editTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let addButtonTapSubject = PassthroughSubject<MealType, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State

    private let mealType: MealType
    private var currentState: State?

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
        addSubview(contentContainerView)
        addSubview(editButton)
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
        case .snack:
            title = "야식"
        }
        titleLabel.setText(title, style: .hd20, color: .white)
    }

    private func configureEditButton() {
        let attributed = NSMutableAttributedString(
            attributedString: Typography.p14.styled("수정", color: .white))
        attributed.addAttribute(
            .underlineStyle, value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: 0, length: attributed.length))
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
        case .processing(let record):
            showProcessingState(record: record)
        case .recorded(let record):
            showRecordedState(record: record)
        }
    }

    // MARK: - State Rendering

    private func showEmptyState() {
        editButton.isHidden = true

        let imageView = UIImageView()
        imageView.image = DesignSystemAsset.emptyMeal.image
        imageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.setText("오늘의 음식 사진을 촬영해보세요", style: .p12, color: .gray100)
        label.textAlignment = .center

        let container = DashedBorderView()
        container.cornerRadius = 16
        container.backgroundColor = .sd900
        container.layer.cornerRadius = 16
        container.clipsToBounds = true
        container.addSubview(imageView)
        container.addSubview(label)

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-(Constants.emptyTextTopSpacing / 2))
            $0.size.equalTo(Constants.emptyImageSize)
        }

        label.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(imageView.snp.bottom).offset(Constants.emptyTextTopSpacing)
        }

        contentContainerView.addSubview(container)
        container.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.height.equalTo(container.snp.width)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(emptyStateTapped))
        container.addGestureRecognizer(tapGesture)
    }

    private func showProcessingState(record: FoodRecord) {
        editButton.isHidden = true

        let imageURL = record.photos.first?.imageURL
        let pendingView = PendingFoodRecordCardView(imageURL: imageURL)
        contentContainerView.addSubview(pendingView)
        pendingView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(Constants.pendingCardHorizontalInset)
            $0.height.equalTo(pendingView.snp.width)
        }
    }

    private func showRecordedState(record: FoodRecord) {
        editButton.isHidden = false

        let recordedView = MealRecordedContentView(
            records: [record],
            onCopyTapped: { [weak self] record in
                self?.copyTapSubject.send(record)
            },
            onShareTapped: { [weak self] record in
                self?.shareTapSubject.send(record)
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

    @objc private func emptyStateTapped() {
        addButtonTapSubject.send(mealType)
    }

    @objc private func editTapped() {
        guard case .recorded(let record) = currentState else { return }
        editTapSubject.send(record)
    }
}

// MARK: - State

extension MealSectionView {
    enum State: Equatable {
        case empty
        case processing(FoodRecord)
        case recorded(FoodRecord)
    }
}
