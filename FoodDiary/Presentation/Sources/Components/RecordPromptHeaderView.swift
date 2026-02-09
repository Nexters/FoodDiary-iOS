//
//  RecordPromptHeaderView.swift
//  Presentation
//

import UIKit
import DesignSystem

/// 음식 기록 안내 헤더 뷰
///
/// "이번주 음식을 기록해 보세요" 서브타이틀과
/// "길동님의 음식 기록\n지금 바로 쓸 수 있어요" 타이틀을 포함하는 Vertical StackView 컴포넌트
public final class RecordPromptHeaderView: UIStackView {
    // MARK: - UI Components

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.setText("이번주 음식을 기록해 보세요", style: .p12, color: DesignSystemAsset.gray050.color)
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setText("길동님의 음식 기록\n지금 바로 쓸 수 있어요", style: .hd20, color: DesignSystemAsset.gray050.color)
        return label
    }()

    // MARK: - Initialization

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        axis = .vertical
        spacing = 12

        addArrangedSubview(subtitleLabel)
        addArrangedSubview(titleLabel)
    }
}
