//
//  InsightKeywordsView.swift
//  Presentation
//

import Domain
import SnapKit
import UIKit

final class InsightKeywordsView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let inset: CGFloat = 20
        static let tagHeight: CGFloat = 36
        static let horizontalSpacing: CGFloat = 8
        static let verticalSpacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let tagsContainer = UIView()
    private let keywords: [KeywordStat]
    private var tagViews: [UIView] = []
    private var tagsContainerHeightConstraint: Constraint?
    private var lastTagsHeight: CGFloat = 0

    // MARK: - Init

    init(keywords: [KeywordStat]) {
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
        addSubview(titleLabel)
        addSubview(tagsContainer)

        tagViews = keywords.map { makeTagView(text: $0.keyword) }
        tagViews.forEach { tagsContainer.addSubview($0) }
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(Constants.inset)
        }

        tagsContainer.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(Constants.inset)
            $0.bottom.equalToSuperview().inset(Constants.inset)
            tagsContainerHeightConstraint = $0.height.equalTo(Constants.tagHeight).constraint
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTagLayout()
    }

    private func updateTagLayout() {
        let containerWidth = tagsContainer.bounds.width
        guard containerWidth > 0 else { return }

        var x: CGFloat = 0
        var y: CGFloat = 0

        for tagView in tagViews {
            let width = tagWidth(for: tagView)
            if x + width > containerWidth, x > 0 {
                x = 0
                y += Constants.tagHeight + Constants.verticalSpacing
            }
            tagView.frame = CGRect(x: x, y: y, width: width, height: Constants.tagHeight)
            x += width + Constants.horizontalSpacing
        }

        let totalHeight = tagViews.isEmpty ? Constants.tagHeight : y + Constants.tagHeight
        guard totalHeight != lastTagsHeight else { return }
        lastTagsHeight = totalHeight
        tagsContainerHeightConstraint?.update(offset: totalHeight)
        setNeedsLayout()
    }

    private func tagWidth(for tagView: UIView) -> CGFloat {
        guard let label = tagView.subviews.first as? UILabel else { return 80 }
        return ceil(label.intrinsicContentSize.width) + 28
    }

    // MARK: - Tag

    private func makeTagView(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .sd850
        container.layer.cornerRadius = Constants.tagHeight / 2

        let label = UILabel()
        label.setText("#\(text)", style: .p14, color: .gray400)
        container.addSubview(label)

        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
        }

        return container
    }
}
