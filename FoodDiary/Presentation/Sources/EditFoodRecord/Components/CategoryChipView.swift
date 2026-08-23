//
//  CategoryChipView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

/// 카테고리 선택 칩 뷰
final class CategoryChipView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 18
        static let verticalInset: CGFloat = 8
        static let horizontalInset: CGFloat = 20
    }

    // MARK: - Properties

    let genre: FoodGenre
    private(set) var isChipSelected: Bool = false

    var tapPublisher: AnyPublisher<FoodGenre, Never> {
        tapSubject.eraseToAnyPublisher()
    }

    private let tapSubject = PassthroughSubject<FoodGenre, Never>()

    // MARK: - UI Components

    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    init(genre: FoodGenre) {
        self.genre = genre
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupGesture()
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = Constants.cornerRadius
        clipsToBounds = true
        addSubview(label)
    }

    private func setupConstraints() {
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(
                top: Constants.verticalInset,
                left: Constants.horizontalInset,
                bottom: Constants.verticalInset,
                right: Constants.horizontalInset
            ))
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    // MARK: - Public Methods

    func setSelected(_ selected: Bool) {
        isChipSelected = selected
        updateAppearance()
    }

    // MARK: - Private Methods

    private func updateAppearance() {
        if isChipSelected {
            backgroundColor = .primary
            layer.borderWidth = 0
            label.setText(genre.displayName, style: .p14, color: .white)
        } else {
            backgroundColor = .white
            layer.borderWidth = 1
            layer.borderColor = UIColor.gray200.cgColor
            label.setText(genre.displayName, style: .p14, color: .gray850)
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        tapSubject.send(genre)
    }
}
