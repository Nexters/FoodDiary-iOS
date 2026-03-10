//
//  InsightKeywordsView.swift
//  Presentation
//

import SnapKit
import UIKit

final class InsightKeywordsView: UIView {

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let tagsStackView = UIStackView()
    private let keywords: [String]

    // MARK: - Init

    init(keywords: [String]) {
        self.keywords = keywords
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .sd900
        layer.cornerRadius = 16
        clipsToBounds = true

        titleLabel.setText("나의 입맛과\n가장 잘 어울리는 키워드", style: .hd16, color: .gray050)
        titleLabel.numberOfLines = 2

        tagsStackView.axis = .horizontal
        tagsStackView.spacing = 8
        tagsStackView.alignment = .center
        tagsStackView.distribution = .equalSpacing

        for keyword in keywords {
            tagsStackView.addArrangedSubview(makeTagView(text: keyword))
        }

        addSubview(titleLabel)
        addSubview(tagsStackView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        tagsStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(32)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    // MARK: - Tag

    private func makeTagView(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .sd850

        let label = UILabel()
        label.setText("#\(text)", style: .p14, color: .gray400)

        container.addSubview(label)

        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
        }

        container.snp.makeConstraints {
            $0.height.equalTo(36)
        }

        container.layer.cornerRadius = 18

        return container
    }
}
