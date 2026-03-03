//
//  RecordPromptHeaderView.swift
//  Presentation
//

import UIKit
import DesignSystem

/// 음식 기록 안내 헤더 뷰
public final class RecordPromptHeaderView: UIStackView {
    // MARK: - Properties

    private let userName: String

    // MARK: - UI Components

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.setText("이번주 음식을 기록해 보세요", style: .p12, color: DesignSystemAsset.gray050.color)
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setText("\(userName)님의 음식 기록,\n지금 바로 쓸 수 있어요", style: .hd20, color: DesignSystemAsset.gray050.color)
        return label
    }()

    // MARK: - Initialization

    public init(userName: String = "") {
        self.userName = userName
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    public func configure(nickname: String) {
        titleLabel.setText("\(nickname)님의 음식 기록,\n지금 바로 쓸 수 있어요", style: .hd20, color: DesignSystemAsset.gray050.color)
    }

    // MARK: - Setup

    private func setupUI() {
        axis = .vertical
        spacing = 12

        addArrangedSubview(subtitleLabel)
        addArrangedSubview(titleLabel)
    }
}
