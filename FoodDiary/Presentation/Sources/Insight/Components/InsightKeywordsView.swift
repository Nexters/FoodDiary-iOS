//
//  InsightKeywordsView.swift
//  Presentation
//

import SnapKit
import UIKit

final class InsightKeywordsView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let tagHeight: CGFloat = 32
        static let tagHorizontalPadding: CGFloat = 14
        static let tagSpacing: CGFloat = 8
        static let lineSpacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let tagsContainerView = UIView()
    private let keywords: [String]
    private var didLayoutTags = false

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

        titleLabel.setText("💬 키워드", style: .hd18)
        addSubview(titleLabel)
        addSubview(tagsContainerView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        tagsContainerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(0)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard !didLayoutTags else { return }
        layoutTags()
    }

    // MARK: - Tag Layout

    private func layoutTags() {
        let containerWidth = tagsContainerView.bounds.width
        guard containerWidth > 0 else { return }
        didLayoutTags = true

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0

        for keyword in keywords {
            let tagView = makeTagView(text: keyword)
            let tagSize = tagView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

            if currentX + tagSize.width > containerWidth, currentX > 0 {
                currentX = 0
                currentY += Constants.tagHeight + Constants.lineSpacing
            }

            tagView.frame = CGRect(
                x: currentX,
                y: currentY,
                width: tagSize.width,
                height: Constants.tagHeight
            )
            tagsContainerView.addSubview(tagView)
            currentX += tagSize.width + Constants.tagSpacing
        }

        let totalHeight = currentY + Constants.tagHeight
        tagsContainerView.snp.updateConstraints {
            $0.height.equalTo(totalHeight)
        }
    }

    private func makeTagView(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .sd700
        container.layer.cornerRadius = Constants.tagHeight / 2

        let label = UILabel()
        label.setText("#\(text)", style: .p14, color: .gray050)
        container.addSubview(label)

        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Constants.tagHorizontalPadding)
            $0.centerY.equalToSuperview()
        }

        container.snp.makeConstraints {
            $0.height.equalTo(Constants.tagHeight)
        }

        return container
    }
}
