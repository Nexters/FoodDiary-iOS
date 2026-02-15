//
//  EmptyFoodRecordView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

/// 음식 기록이 없을 때 표시되는 빈 상태 뷰
final class EmptyFoodRecordView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 16
        static let addImageSize: CGFloat = 140
        static let placeholderTopSpacing: CGFloat = 25
    }

    // MARK: - Publishers

    var addButtonTapPublisher: AnyPublisher<Void, Never> {
        addButtonTapSubject.eraseToAnyPublisher()
    }

    private let addButtonTapSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Components

    private let dashedBorderView = DashedBorderView(strokeColor: .gray900)

    private let contentView = UIView()

    private let addImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.add.image
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()


    // MARK: - Init

    init(text: String) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        placeholderLabel.setText(text, style: .p14, color: .gray050)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        dashedBorderView.cornerRadius = Constants.cornerRadius
        dashedBorderView.backgroundColor = .sd900
        dashedBorderView.layer.cornerRadius = Constants.cornerRadius
        dashedBorderView.clipsToBounds = true
        addSubview(dashedBorderView)
        dashedBorderView.addSubview(contentView)

        contentView.addSubview(addImageView)
        contentView.addSubview(placeholderLabel)
    }

    private func setupConstraints() {
        dashedBorderView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        addImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-(Constants.placeholderTopSpacing / 2))
            $0.size.equalTo(Constants.addImageSize)
        }

        placeholderLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(addImageView.snp.bottom).offset(Constants.placeholderTopSpacing)
        }
    }

    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions

    @objc private func viewTapped() {
        addButtonTapSubject.send()
    }
}
