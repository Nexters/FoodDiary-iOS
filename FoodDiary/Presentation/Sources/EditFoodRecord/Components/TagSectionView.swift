//
//  TagSectionView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

/// 태그 섹션 (태그 칩 + 추가/삭제)
final class TagSectionView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let chipHeight: CGFloat = 36
        static let chipSpacing: CGFloat = 8
        static let chipHorizontalInset: CGFloat = 14
        static let cornerRadius: CGFloat = 18
    }

    // MARK: - Publishers

    var addTagTapPublisher: AnyPublisher<Void, Never> {
        addTagTapSubject.eraseToAnyPublisher()
    }

    var removeTagPublisher: AnyPublisher<Int, Never> {
        removeTagSubject.eraseToAnyPublisher()
    }

    private let addTagTapSubject = PassthroughSubject<Void, Never>()
    private let removeTagSubject = PassthroughSubject<Int, Never>()

    // MARK: - State

    private var tags: [String] = []

    // MARK: - UI Components

    private let flowLayoutView = UIView()

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
        addSubview(flowLayoutView)
    }

    private func setupConstraints() {
        flowLayoutView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Public Methods

    func configure(tags: [String]) {
        self.tags = tags
        rebuildLayout()
    }

    // MARK: - Private Methods

    private func rebuildLayout() {
        flowLayoutView.subviews.forEach { $0.removeFromSuperview() }

        var chipViews: [UIView] = []

        for (index, tag) in tags.enumerated() {
            let chip = createTagChip(text: "#\(tag)", index: index)
            chipViews.append(chip)
        }

        let addButton = createAddButton()
        chipViews.append(addButton)

        layoutChips(chipViews)
    }

    private func createTagChip(text: String, index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .sd800
        container.layer.cornerRadius = Constants.cornerRadius
        container.clipsToBounds = true

        let label = UILabel()
        label.setText(text, style: .p14, color: .gray400)

        let deleteButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        deleteButton.setImage(
            UIImage(systemName: "xmark")?.withConfiguration(config),
            for: .normal
        )
        deleteButton.backgroundColor = UIColor.sdBase.withAlphaComponent(0.8)
        deleteButton.tintColor = .gray400
        deleteButton.layer.cornerRadius = 8
        deleteButton.clipsToBounds = true
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(removeTagTapped(_:)), for: .touchUpInside)

        container.addSubview(label)
        container.addSubview(deleteButton)

        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.chipHorizontalInset)
            $0.centerY.equalToSuperview()
        }

        deleteButton.snp.makeConstraints {
            $0.leading.equalTo(label.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().offset(-10)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        container.snp.makeConstraints {
            $0.height.equalTo(Constants.chipHeight)
        }

        return container
    }

    private func createAddButton() -> UIView {
        let button = UIButton()
        button.backgroundColor = .sd900
        button.layer.cornerRadius = Constants.chipHeight / 2
        button.clipsToBounds = true

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(
            UIImage(systemName: "plus")?.withConfiguration(config),
            for: .normal
        )
        button.tintColor = .white
        button.addTarget(self, action: #selector(addTagTapped), for: .touchUpInside)

        button.snp.makeConstraints {
            $0.size.equalTo(Constants.chipHeight)
        }

        return button
    }

    private func layoutChips(_ chips: [UIView]) {
        let maxWidth = UIScreen.main.bounds.width - 40

        var currentRow = UIStackView()
        currentRow.axis = .horizontal
        currentRow.spacing = Constants.chipSpacing

        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = Constants.chipSpacing
        containerStack.alignment = .leading

        flowLayoutView.addSubview(containerStack)
        containerStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        var currentRowWidth: CGFloat = 0

        for chip in chips {
            chip.layoutIfNeeded()
            let chipWidth = chip.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
            let neededWidth =
                currentRowWidth + (currentRowWidth > 0 ? Constants.chipSpacing : 0) + chipWidth

            if neededWidth > maxWidth && currentRowWidth > 0 {
                containerStack.addArrangedSubview(currentRow)
                currentRow = UIStackView()
                currentRow.axis = .horizontal
                currentRow.spacing = Constants.chipSpacing
                currentRowWidth = 0
            }

            currentRow.addArrangedSubview(chip)
            currentRowWidth += (currentRowWidth > 0 ? Constants.chipSpacing : 0) + chipWidth
        }

        if currentRow.arrangedSubviews.count > 0 {
            containerStack.addArrangedSubview(currentRow)
        }
    }

    // MARK: - Actions

    @objc private func removeTagTapped(_ sender: UIButton) {
        removeTagSubject.send(sender.tag)
    }

    @objc private func addTagTapped() {
        addTagTapSubject.send()
    }
}
