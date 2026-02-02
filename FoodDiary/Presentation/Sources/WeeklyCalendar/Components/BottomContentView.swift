//
//  BottomContentView.swift
//  Presentation
//

import Combine
import DesignSystem
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

    var copyTapPublisher: AnyPublisher<String, Never> {
        copyTapSubject.eraseToAnyPublisher()
    }

    private let addButtonTapSubject = PassthroughSubject<Void, Never>()
    private let cardStackTapSubject = PassthroughSubject<FoodRecord, Never>()
    private let copyTapSubject = PassthroughSubject<String, Never>()
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
    private let emptyStateView: UIView = {
        let view = UIView()
        return view
    }()

    private let addButton: UIButton = {
        let button = UIButton()
        button.setImage(DesignSystemAsset.add.image, for: .normal)
        return button
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 음식 사진을 추가해보세요."
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()

    private let photoCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    // Card Stack UI (when records exist)
    private let cardStackStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.clipsToBounds = false
        return view
    }()

    private var cardStackView: FoodRecordCardStackView?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)

        // Empty State
        containerView.addSubview(emptyStateView)
        emptyStateView.addSubview(addButton)
        emptyStateView.addSubview(placeholderLabel)
        emptyStateView.addSubview(photoCountLabel)

        // Card Stack State
        containerView.addSubview(cardStackStateView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }

        // Empty State Constraints
        emptyStateView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        addButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-20)
            $0.width.height.equalTo(120)
        }

        placeholderLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(addButton.snp.bottom).offset(16)
        }

        photoCountLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(placeholderLabel.snp.bottom).offset(4)
        }

        // Card Stack State Constraints
        cardStackStateView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func setupActions() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    // MARK: - Configuration

    func configure(hasRecords: Bool, records: [FoodRecord], photoCount: Int) {
        if hasRecords, let firstRecord = records.first {
            showCardStackState(record: firstRecord, totalCount: records.count)
        } else {
            showEmptyState(photoCount: photoCount)
        }
    }

    private func showEmptyState(photoCount: Int) {
        emptyStateView.isHidden = false
        cardStackStateView.isHidden = true

        if photoCount > 0 {
            placeholderLabel.text = "음식 사진을 추가해보세요."
            photoCountLabel.text = "올리지 않은 음식 사진 \(photoCount)장"
            photoCountLabel.isHidden = false
        } else {
            placeholderLabel.text = "오늘의 음식 사진을 추가해보세요."
            photoCountLabel.isHidden = true
        }
    }

    private func showCardStackState(record: FoodRecord, totalCount: Int) {
        emptyStateView.isHidden = true
        cardStackStateView.isHidden = false

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

        newCardStackView.copyTapPublisher
            .sink { [weak self] address in
                self?.copyTapSubject.send(address)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        addButtonTapSubject.send()
    }
}
