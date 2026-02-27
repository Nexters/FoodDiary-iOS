//
//  NoteContentView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// AI 요약 노트를 표시하는 뷰
final class NoteContentView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let containerPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 10
        static let headerIconSize: CGFloat = 10
        static let headerSpacing: CGFloat = 4
        static let contentTopSpacing: CGFloat = 12
    }

    // MARK: - UI Components

    private let headerIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = DesignSystemAsset.iconAi.image
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let headerLabel = UILabel()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(note: String) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        configure(note: note)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .sd900
        layer.cornerRadius = Constants.cornerRadius
        clipsToBounds = true

        addSubview(headerIconView)
        addSubview(headerLabel)
        addSubview(contentLabel)
    }

    private func setupConstraints() {
        headerIconView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(Constants.containerPadding)
            $0.size.equalTo(Constants.headerIconSize)
        }

        headerLabel.snp.makeConstraints {
            $0.centerY.equalTo(headerIconView)
            $0.leading.equalTo(headerIconView.snp.trailing).offset(Constants.headerSpacing)
            $0.trailing.lessThanOrEqualToSuperview().inset(Constants.containerPadding)
        }

        contentLabel.snp.makeConstraints {
            $0.top.equalTo(headerIconView.snp.bottom).offset(Constants.contentTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(Constants.containerPadding)
            $0.bottom.equalToSuperview().inset(Constants.containerPadding)
        }
    }

    private func configure(note: String) {
        headerLabel.setText("AI가 요약했어요", style: .p12, color: .gray050)
        contentLabel.setText(note, style: .p12, color: .gray100, lineSpacing: 4)
    }
}
